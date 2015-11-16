#
# docker Makefile -- combine some usefull stuff
#

.PHONY: help list status create delete
.PHONY: boot shutdown destroy stats destroy plugins configs
.PHONY: images fetch destroyi
.PHONY: startup teardown construct cleanup wipeout

# --------- Defaults

SHELL := /bin/bash
DOCKERHOST = dockerhost
ENV = develop
CONFIG_F = jenkins/config.xml.j2
PLUGIN_F = plugins.ini
BASE_D = .
PB_D = $(BASE_D)/playbooks/$(DOCKERHOST)
TAG_D = $(BASE_D)/roles/$(DOCKERHOST)/files
CNFG_D = $(BASE_D)/roles/$(DOCKERHOST)/defaults
FILES_D = $(BASE_D)/roles/$(DOCKERHOST)/files
A_CFG = $(BASE_D)/configs/ansible.cfg

ifeq ($(wildcard $(CNFG_D)/envs/$(APP)/$(ENV).json),)
CONFIGS =
else
CONFIGS = -e "@$(CNFG_D)/envs/$(APP)/$(ENV).json"
endif
ifneq ($(wildcard configs/.secrets/vpf.txt),)
CONFIGS += --vault-password-file ./configs/.secrets/vpf.txt
endif

# --------- Rules

help:
	@echo "-- Help ---------"
	@echo "* make APP=<app folder> *) [ENV=<environment> *)] ((boot | shutdown | destroy) [EXTRAS=<ansible-playbook params>]) | stats)"
	@echo "* make INFRA=<infra name from list>  [ENV=<environment> *)] startup | teardown | construct | cleanup"
	@echo "* make ENV=<Environment name> *) PORT=<Port extension to use> **) create | [DELETE=true ***)] delete"
	@echo "* make TAG=<Dockerfile folder> build"
	@echo "* make IMG=<image from dockerhub> fetch"
	@echo "* make IMG=<image from images> *) destroyi"
	@echo "* make status | images | list | wipeout ***)"
	@echo
	@echo "*) see 'make list' output for available options; default: ENV = develop"
	@echo "**) Port extension to use with normal prefix 80 or db prefix 90; e.g. normal (80) + extenison (85) = port (8085)"
	@echo "***) Very dangerous, since deletes all associated folders on 'dockerhost'"
	@echo "****) Very dangerous, since it kills all docker containers on 'dockerhost'"
	@echo
	@echo "-- Defaults ---------"
	@echo "* ENV = $(ENV)"
	@echo "* TAG_D = $(TAG_D)"
	@echo "* CNFG_D = $(CNFG_D)"
	@echo "* FILES_D = $(FILES_D)"
	@echo "* A_CFG = $(A_CFG)"

# -------- Playbook handling

verify_playbook:
	$(eval PLAYBOOKPATH=$(PB_D)/$(PLAYBOOK).yml)
	@test -f $(PLAYBOOKPATH) || (echo "Error: No playbook found!" && exit 1)

execute: verify_playbook
	@echo
	@echo "--- Execute playbook '$(PLAYBOOK)'  ------------------------"

ifeq ($(wildcard $(A_CFG)),)
	@echo ansible-playbook $(PLAYBOOKPATH) $(APPIMG) $(CONFIGS) $(EXTRAS)
else
	ANSIBLE_CONFIG=$(A_CFG) ansible-playbook $(PLAYBOOKPATH) $(APPIMG) $(CONFIGS) $(EXTRAS)
endif
	@echo

# -------- Application handling

verify:
	@test "$(APP)" && test -d $(CNFG_D)/envs/$(APP)/ || (echo "Error: APP not set or APP folder not found! ($(CNFG_D)/envs/$(APP)/" && exit 1)
	@test "$(ENV)" && test -s $(CNFG_D)/envs/$(APP)/$(ENV).json || (echo "Error: ENV not set or ENV json not found! ($(CNFG_D)/envs/$(APP)/$(ENV).json)" && exit 1)
	$(eval APPIMG=-e "image=$(APP)")

extras:
	@[[ -f $(FILES_D)/$(APP)/$(CONFIG_F) ]] && make APP=$(APP) ENV=$(ENV) configs || echo "----- No extra files available!"
	@[[ -f $(FILES_D)/$(APP)/$(PLUGIN_F) ]] && make APP=$(APP) ENV=$(ENV) plugins || echo "----- No extra plugins configured!"
	@echo "--- Extras done ------------------------"
	@echo

boot: PLAYBOOK=start
boot: verify extras execute stats status
	@echo "--- Boot done ------------------------"
	@echo

shutdown: PLAYBOOK=stop
shutdown: verify stats execute status
	@echo "--- Shutdown done ------------------------"
	@echo

destroy: PLAYBOOK=remove
destroy: verify stats execute status
	@echo "--- Destroy done ------------------------"
	@echo

stats: verify
	@echo "--- Stats ------------------------"
	@[[ `docker ps | grep $(APP)_$(ENV)` ]] && docker logs --tail="30" $(APP)_$(ENV) || echo No stats available
	@echo

status:
	@echo "--- Status ------------------------"
	@docker ps -a -f name=$(APP)_$(ENV)
	@echo

plugins: PLAYBOOK=plugins
plugins: verify execute
	@echo "--- Plugins done ------------------------"
	@echo

configs: PLAYBOOK=configs
configs: verify execute
	@echo "--- Configs done ------------------------"
	@echo

# -------- Environment handling

verify_env:
	@test "$(ENV)" || (echo "Error: ENV not set!" && exit 1)

verify_port:
	@test "$(PORT)" || (echo "Error: PORT not set!" && exit 1)

create: ENV=
create: PLAYBOOK=create
create: EXTRAS += -e "env_name=$(ENV)" -e "port=$(PORT)"
create: verify_env verify_port execute
	@echo "--- Create done ------------------------"
	@echo

delete: ENV=
delete: DELETE=False
delete: PLAYBOOK=delete
delete: EXTRAS += -e "env_name=$(ENV)" -e "clean_up=$(DELETE)"
delete: verify_env execute
	@echo "--- Delete done ------------------------"
	@echo

# -------- Image handling

verify_tag:
	$(eval APP=$(TAG))
	@test "$(APP)" && test -d $(TAG_D)/$(TAG)/ || (echo "Error: TAG not set or TAG folder not found! ($(TAG_D)/$(TAG)/)" && exit 1)
	$(eval APPIMG=-e "image=$(APP)")

build: PLAYBOOK=build
build: verify_tag execute
	@echo "--- Build done ------------------------"
	@echo

images:
	@docker images

verify_img:
	@test "$(IMG)" || (echo "Error: IMG not set!" && exit 1)

fetch: verify_img
	@docker pull ${IMG}

destroyi: verify_img
	@docker rmi ${IMG}

# -------- Wipe.out or debugging

wipeout:
	@echo "--- Wipeout ------------------------"
	@for j in $$(docker ps -a -q); \
	do \
		echo Removing $$j; \
		docker stop $$j; \
		docker rm $$j; \
		echo; \
	done
	@docker ps -a

# -------- Infra handling

verify_infra:
	@test "$(INFRA)" && test -s $(CNFG_D)/infra/$(INFRA).txt || (echo "Error: INFRA not set or INFRA txt not found! ($(CNFG_D)/infra/$(INFRA).txt)" && exit 1)

startup: verify_infra
	@echo "--- Startup '$(INFRA)' ------------------------"
	@for l in `cat $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo "----- Booting $$l ------------------------"; \
		make APP=$$l ENV=$(ENV) boot; \
		echo; \
	done
	@docker ps -a
	@echo "--- Startup '$(INFRA)' done ------------------------"

teardown: verify_infra
	@echo "--- Teardown '$(INFRA)' -----------------------"
	@for l in `tac $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo Shuting down $$l; \
		make APP=$$l ENV=$(ENV) shutdown; \
		echo; \
	done
	@docker ps -a
	@echo "--- Teardown '$(INFRA)' done ------------------------"

construct: verify_infra
	@echo "--- Construct '$(INFRA)' ------------------------"
	@for l in `cat $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo Building $$l; \
		make TAG=$$l build; \
		echo; \
	done
	@docker images
	@echo "--- Construct '$(INFRA)' done ------------------------"

cleanup: verify_infra
	@echo "--- Cleanup '$(INFRA)' ------------------------"
	@for l in `cat $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo Removing $$l; \
		make APP=$$l ENV=$(ENV) destroy; \
		echo; \
	done
	@docker ps -a
	@echo "--- Cleanup '$(INFRA)' done ------------------------"

list:
	@echo "--- List Infrastructures [$(CNFG_D)/infra/] ------------------------"
	@pushd $(CNFG_D)/infra/ > /dev/null; ls -1 *.txt | cut -d _ -f 2 | cut -d . -f 1; popd > /dev/null
	@echo
	@echo "--- List Application Stacks [$(CNFG_D)/envs/] ------------------------"
	@pushd $(CNFG_D)/envs/ > /dev/null; ls -1dR */; popd > /dev/null
	@echo
	@echo "--- List Environments in Application Stacks [$(CNFG_D)/envs/] ------------------------"
	@pushd $(CNFG_D)/envs/ > /dev/null; ls -1dR **/*.json | cut -d / -f 2 | cut -d . -f 1 | sort -u; popd > /dev/null
	@echo
	@echo "--- List Custom Docker Images [$(TAG_D)] ------------------------"
	@pushd $(TAG_D) > /dev/null; ls -1dR */; popd > /dev/null
	@echo
