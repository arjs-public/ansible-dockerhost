#
# docker Makefile -- combine some usefull stuff
#

.PHONY: help list status create delete ping
.PHONY: boot shutdown destroy stats destroy plugins configs
.PHONY: images fetch destroyi
.PHONY: startup teardown construct cleanup wipeout

# --------- Defaults

SHELL := /bin/bash
DOCKERHOST = dockerhost
ENV = develop
CONFIG_F = jenkins/config.xml.j2
PLUGIN_F = plugins.ini
APP_F = app.py
$(eval BASE_D=$(shell pwd))
#$(info $(BASE_D))
PB_D = $(BASE_D)/playbooks
TAG_D = $(BASE_D)/roles/files
CNFG_D = $(BASE_D)/roles/defaults
FILES_D = $(BASE_D)/roles/files
$(eval ANSIBLE_CFG=$(shell netstat -all | grep 6379 > /dev/null && echo redis || echo default))
#$(info ANSIBLE_CFG: $(ANSIBLE_CFG))
A_CFG = $(BASE_D)/configs/$(ANSIBLE_CFG).cfg
VPF_FILE = configs/.secrets/vpf.txt
#$(info A_CFG: $(A_CFG))
INVENTORY = $(BASE_D)/inventory/inventory

ifeq ($(wildcard $(CNFG_D)/envs/$(APP)/$(ENV).json),)
 ifeq ($(wildcard $(CNFG_D)/envs/$(APP)/$(APN)/$(ENV).json),)
 CONFIGS =
 else
 CONFIGS = -e "@$(CNFG_D)/envs/$(APP)/$(APN)/$(ENV).json"
 endif
else
CONFIGS = -e "@$(CNFG_D)/envs/$(APP)/$(ENV).json"
endif
ifneq ($(wildcard $(VPF_FILE)),)
CONFIGS += --vault-password-file ./$(VPF_FILE)
endif

# --------- Rules

help:
	@echo "-- Help ---------"
	@echo "* make APP=<app folder> *? [ENV=<environment> *)] ([EXTRAS=<ansible-playbook params>] [APN=<appname> 6*?] (boot | shutdown | [DELETE=true ***?] destroy)) | stats)"
	@echo "* make INFRA=<infra name from list>  ([ENV=<environment> *?] startup | teardown | construct | [DELETE=true ***?] cleanup)"
	@echo "* make ENV=<Environment name> *? [APP=<appgroup> 5*?] [APN=<appname> 6*?] (PORT=<Port extension to use> **? create | [DELETE=true ***?] delete)"
	@echo "* make TAG=<Dockerfile folder> build"
	@echo "* make IMG=<image from dockerhub> fetch"
	@echo "* make IMG=<image from images> *? destroyi"
	@echo "* make ping | status | images | list | wipeout ****?"
	@echo
	@echo "*? see 'make list' output for available options; default: ENV = develop"
	@echo "**? Port extension to use with normal prefix 80 or db prefix 90; e.g. normal (80) + extenison (85) = port (8085)"
	@echo "***? Very dangerous, since deletes all associated folders on 'dockerhost'"
	@echo "****? Very dangerous, since it kills all docker containers on 'dockerhost'"
	@echo "*****? APP empty means ENV Environment in all Applications; APP set, means ENV Environment for specific Application"
	@echo "******? APN needed for app image"
	@echo
	@echo "-- Defaults ---------"
	@echo "* ENV = $(ENV)"
	@echo "* BASE_D = $(BASE_D)"
	@echo "* PB_D = $(PB_D)"
	@echo "* TAG_D = $(TAG_D)"
	@echo "* CNFG_D = $(CNFG_D)"
	@echo "* FILES_D = $(FILES_D)"
	@echo "* A_CFG = $(A_CFG)"

# -------- Playbook handling

verify_playbook:
	@echo "---- Verify playbook $(PB_D)/$(PLAYBOOK).yml"
	$(eval PLAYBOOKPATH=$(PB_D)/$(PLAYBOOK).yml)
	@test -f $(PLAYBOOKPATH) && echo "----- Found playbook $(PB_D)/$(PLAYBOOK).yml" && exit 0 || echo "Error: No playbook found!" && exit 1

execute: verify_playbook
	@echo
	@echo "--- Execute playbook '$(PLAYBOOK)'  ------------------------"

ifeq ($(wildcard $(A_CFG)),)
	@echo Not executed: ansible-playbook $(PLAYBOOKPATH) $(APPIMG) $(CONFIGS) $(EXTRAS)
else
	ANSIBLE_CONFIG=$(A_CFG) ansible-playbook $(PLAYBOOKPATH) $(APPIMG) $(CONFIGS) $(EXTRAS) $(APNEXTRA)
endif
	@echo

# -------- Application handling

verify:
	@test "$(APP)" && test -d $(CNFG_D)/envs/$(APP)/ || (echo "Error: APP not set or APP folder not found! ($(CNFG_D)/envs/$(APP)/" && exit 1)
ifndef APN
	@test "$(ENV)" && test -s $(CNFG_D)/envs/$(APP)/$(ENV).json || (echo "Error: ENV not set or ENV json not found! ($(CNFG_D)/envs/$(APP)/$(ENV).json)" && exit 1)
else
	@test "$(APN)" && test "$(ENV)" && test -s $(CNFG_D)/envs/$(APP)/$(APN)/$(ENV).json || (echo "Error: APN or ENV not set or APN/ENV json not found! ($(CNFG_D)/envs/$(APP)/$(APN)/$(ENV).json)" && exit 1)
	$(eval APNEXTRA=-e "appname=$(APN)")
endif
	$(eval APPIMG=-e "image=$(APP)")

extra_config:
ifeq ($(wildcard $(FILES_D)/$(APP)/$(CONFIG_F)),)
	@echo "---- Config ignorieren"
else
	@[[ -f $(FILES_D)/$(APP)/$(CONFIG_F) ]] && make APP=$(APP) ENV=$(ENV) configs || echo "----- No extra files available!"
endif

extra_plugins:
ifeq ($(wildcard $(FILES_D)/$(APP)/$(PLUGIN_F)),)
	@echo "---- Plugins ignorieren"
else
	@[[ -f $(FILES_D)/$(APP)/$(PLUGIN_F) ]] && make APP=$(APP) ENV=$(ENV) plugins || echo "----- No extra plugins configured!"
endif

extra_appname:
ifeq ($(wildcard $(FILES_D)/$(APP)/apps/$(APN)/$(APP_F)),)
	@echo "---- APP ignorieren"
else
	@[[ -f $(FILES_D)/$(APP)/apps/$(APN)/$(APP_F) ]] && make APP=$(APP) ENV=$(ENV) APN=$(APN) appname || echo "----- No extra appname configured!"
endif

extras: extra_config extra_plugins extra_appname
	@echo "--- Extras done ------------------------"
	@echo

boot: PLAYBOOK=boot
boot: verify extras execute stats status
	@echo "--- Boot done ------------------------"
	@echo

shutdown: PLAYBOOK=shutdown
shutdown: verify stats execute status
	@echo "--- Shutdown done ------------------------"
	@echo

destroy: DELETE=false
destroy: EXTRAS += -e "clean_up=$(DELETE)"
destroy: PLAYBOOK=destroy
destroy: verify stats execute status
	@echo "--- Destroy done ------------------------"
	@echo

stats: verify
	@echo "--- Stats ------------------------"
	@[[ `docker ps | grep $(APP)_$(ENV)` ]] && docker logs --tail="30" $(APP)_$(ENV) || echo No stats available for $(APP)_$(ENV)
	@[[ `docker ps | grep $(APP)_$(APN)_$(ENV)` ]] && docker logs --tail="30" $(APP)_$(APN)_$(ENV) || echo No stats available for $(APP)_$(APN)_$(ENV)
	@echo

status:
	@echo "--- Status ------------------------"
	@test "$(APP)" && docker ps -a -f name=$(APP) | tail -n +2 || \
	test "$(APP)" && test "$(ENV)" && docker ps -a -f name=$(APP)_$(ENV) | tail -n +2 || docker ps -a
	@echo

configs: PLAYBOOK=jenkins/configs
configs: verify execute
	@echo "--- Configs done ------------------------"
	@echo

plugins: PLAYBOOK=jenkins/plugins
plugins: verify execute
	@echo "--- Plugins done ------------------------"
	@echo

appname: APN=
appname: EXTRAS += -e "appname=$(APN)"
appname: PLAYBOOK=$(APP)/appname
appname: verify execute
	@echo "--- PyAPP done ------------------------"
	@echo

# -------- Environment handling

verify_env:
	@test "$(ENV)" || (echo "Error: ENV not set!" && exit 1)

verify_port:
	@test "$(PORT)" || (echo "Error: PORT not set!" && exit 1)

verify_app:
	$(eval APPIMG=-e "image=$(APP)")

verify_extra:
ifdef APN
	$(eval APNEXTRA=-e "appname=$(APN)")
endif

create: ENV=
create: PLAYBOOK=create
create: EXTRAS += -e "env_name=$(ENV)" -e "port=$(PORT)"
create: verify_env verify_port verify_app verify_extra execute
	@echo "--- Create done ------------------------"
	@echo

delete: ENV=
delete: DELETE=false
delete: PLAYBOOK=delete
delete: EXTRAS += -e "env_name=$(ENV)"
delete: EXTRAS += -e "clean_up=$(DELETE)"
delete: verify_env verify_app verify_extra execute
	@echo "--- Delete done ------------------------"
	@echo

# -------- Image handling

verify_tag:
	$(eval APP=$(TAG))
	@test "$(APP)" && test -d $(TAG_D)/$(TAG)/ || (echo "Error: TAG not set or TAG folder not found! ($(TAG_D)/$(TAG)/)" && exit 1)
	$(eval APPIMG=-e "image=$(APP)")

build: PLAYBOOK=build
build: verify_tag execute
	docker images | grep $(TAG)
	@echo "--- Build done ------------------------"
	@echo

images: PLAYBOOK=images
images: execute status
	@echo "--- Images done ------------------------"
	@echo

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

cleanup: DELETE=false
cleanup: verify_infra
	@echo "--- Cleanup '$(INFRA)' ------------------------"
	@for l in `cat $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo Removing $$l; \
		make APP=$$l ENV=$(ENV) DELETE=$(DELETE) destroy; \
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

ansible_cmd_check:
	@which ansible > /dev/null || (echo "Error: ansible command not found!" && exit 1)
    
ping: ansible_cmd_check
	@echo "--- ping docker host [$(DOCKERHOST)] ------------------------"
	@ansible -i $(INVENTORY) -m ping $(DOCKERHOST)
