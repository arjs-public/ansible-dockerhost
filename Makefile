#
# Makefile -- combine some usefull stuff
#

.PHONY: help list status create delete ping
.PHONY: try develop test stage production
.PHONY: start stop remove stats destroy plugins configs setup deploy
.PHONY: images fetch removeimage
.PHONY: startup teardown construct cleanup wipeout

# --------- Defaults

SHELL := /bin/bash
DOCKERHOST = dockerhost
#ENV = develop
CONFIG_F = config.xml.j2
PLUGIN_F = plugins.ini
APP_F = app.py
$(eval BASE_D=$(shell pwd))
# $(info [Info] Use BASE_D: $(BASE_D))
PB_D_B = $(BASE_D)/playbooks
# $(info [Info] Use PB_D_B: $(PB_D_B))
PB_D_I = $(if $(IMG),$(PB_D_B)/$(IMG),$(PB_D_B))
# $(info [Info] Use PB_D_I: $(PB_D_I))
TAG_D = $(BASE_D)/roles/files
FILES_D = $(BASE_D)/roles/files
TEMPLATES_D = $(BASE_D)/roles/templates
$(eval ANSIBLE_CFG=$(shell netstat -all | grep ' 6379 ' > /dev/null && echo redis || echo default))
# $(info [Info] Use ANSIBLE_CFG: $(ANSIBLE_CFG))
A_CFG = $(BASE_D)/configs/$(ANSIBLE_CFG).cfg
VPF_FILE = configs/.secrets/vpf.txt
# $(info [Info] Use A_CFG: $(A_CFG))
INVENTORY = $(BASE_D)/inventory/inventory

# --------- Rules

help:
	$(info [Info] -- Help ---------)
	$(info [Info] )
	$(info [Info] * make <appname> <environment> <image> setup [EXTRAS=<ansible-playbook params>])
	$(info [Info] * make <appname> <environment> <image> deploy [EXTRAS=<ansible-playbook params>])
	$(info [Info] * make <appname> <environment> <image> start [EXTRAS=<ansible-playbook params>])
	$(info [Info] * make <appname> <environment> <image> stop [EXTRAS=<ansible-playbook params>])
	$(info [Info] * make <appname> <environment> <image> stats [EXTRAS=<ansible-playbook params>])
	$(info [Info] * make <appname> <environment> <image> remove [DELETE=true|*false ***?])
	$(info [Info] * make INFRA=<infra name from list> [ENV=<environment> *?] startup)
	$(info [Info] * make INFRA=<infra name from list> teardown)
	$(info [Info] * make INFRA=<infra name from list> construct)
	$(info [Info] * make INFRA=<infra name from list> [DELETE=true|*false ***?] cleanup)
	$(info [Info] * make ENV=<Environment name> *? [IMG=<appgroup> 5*?] [APP=<app name> 6*?] (PORT=<Port extension to use> **? create | [DELETE=true ***?] delete))
	$(info [Info] * make IMG=<image to build> build)
	$(info [Info] * make IMG=<image from dockerhub> fetch)
	$(info [Info] * make IMG=<image from images> *? removeimage)
	$(info [Info] * make ping | status | images | list | wipeout ****?)
	$(info [Info] )
	$(info [Info] *? see 'make list' output for available options; default: ENV = develop)
	$(info [Info] **? Port extension to use with normal prefix 80 or db prefix 90; e.g. normal (80) + extenison (85) = port (8085))
	$(info [Info] ***? Very dangerous, since deletes all associated folders on 'dockerhost')
	$(info [Info] ****? Very dangerous, since it kills all docker containers on 'dockerhost')
	$(info [Info] *****? IMG empty means ENV Environment in all Applications; IMG set, means ENV Environment for specific Application)
	$(info [Info] ******? APP needed for special image)
	$(info [Info] )
	$(info [Info] -- Defaults ---------)
	$(info [Info] * ENV = $(ENV))
	$(info [Info] * BASE_D = $(BASE_D))
	$(info [Info] * PB_D_B = $(PB_D_B))
	$(info [Info] * PB_D_I = $(PB_D_I))
	$(info [Info] * TAG_D = $(TAG_D))
	$(info [Info] * FILES_D = $(FILES_D))
	$(info [Info] * A_CFG = $(A_CFG))
	$(info [Info] )
	@true

# --------- Include

include configs/makefiles/images.mk
include configs/makefiles/environments.mk
include configs/makefiles/sites.mk
include configs/makefiles/apps.mk

# -------- Helpers handling
	
ending:
	$(info [Info])
	$(info [Info] Finsihed $(PLAYBOOK))
	$(info [Info])

# -------- Verify handling

verify_port:
	@test "$(PORT)" || (echo "[Error] PORT not set!" && exit 1)
	$(info [Info] Use port: $(PORT))
	$(info [Info])

verify: verify_var_env verify_var_app verify_var_img
	$(if $(APP),,$(call SITE_RULE_STD))

# -------- Playbook handling

define SET_EXTRA_VARS
	$(if $(wildcard $(VPF_FILE)),$(eval VPF=--vault-password-file ./$(VPF_FILE)),$(eval VPF=))
    $(info [Info] Using vpf: $(VPF))
	$(if $(wildcard $(CNFG_D)/envs/$(APP)/$(ENV).json),$(eval CONFIGS=-e "@$(CNFG_D)/envs/$(APP)/$(ENV).json"),$(eval CONFIGS=))
	$(if $(wildcard $(CNFG_D)/envs/$(ENV).json),$(eval CONFIGS=-e "@$(CNFG_D)/envs/$(ENV).json"),$(eval CONFIGS=))
    $(info [Info] Using extra variables: $(CONFIGS))
endef

define SET_PLAYBOOK
	$(if $(PLAYBOOK),,$(eval PLAYBOOK=main))
	$(eval PLAYBOOKPATH = $(if $(wildcard $(PB_D_I)/$(PLAYBOOK).yml),$(PB_D_I)/$(PLAYBOOK).yml,$(PB_D_B)/$(PLAYBOOK).yml))
	$(info [Info] Using Playbook: $(PLAYBOOKPATH) ...)	
endef

define VERIFY_PLAYBOOK
	$(info [Info] Verify playbook $(PLAYBOOKPATH) ...)
	$(if $(wildcard $(PLAYBOOKPATH)), 
	  $(info [Info] Found playbook $(PLAYBOOKPATH) ...), 
	  $(error [Error] No playbook found!)
	)
endef

define EXECUTE_ERROR
	$(info [Info])
	$(error [Info] Not executed: ansible-playbook $(PLAYBOOKPATH) $(VPF) $(CONFIGS) $(EXTRA_IMG) $(EXTRA_ENV) $(EXTRA_APP) $(EXTRAS))
endef

define EXECUTE_PLAYBOOK
	$(info [Info])
	@ANSIBLE_CONFIG=$(A_CFG) ansible-playbook $(PLAYBOOKPATH) $(VPF) $(CONFIGS) $(EXTRA_IMG) $(EXTRA_ENV) $(EXTRA_APP) $(EXTRAS)
endef

define EXECUTE
	$(call SET_PLAYBOOK)
	$(call VERIFY_PLAYBOOK)
	$(info [Info] )
	$(info [Info] Execute playbook '$(PLAYBOOK)' ...)
	$(if $(wildcard $(A_CFG)),$(call EXECUTE_PLAYBOOK),$(call EXECUTE_ERROR))
endef

set_extra_vars:
	$(call SET_EXTRA_VARS)

set_playbook:
	$(call SET_PLAYBOOK)

verify_playbook:
	$(call VERIFY_PLAYBOOK)

execute_playbook: 
	$(info [Info] )
	$(info [Info] Execute playbook '$(PLAYBOOK)' ...)
	$(if $(wildcard $(A_CFG)),$(call EXECUTE_PLAYBOOK),$(call EXECUTE_ERROR))

execute: set_extra_vars set_playbook verify_playbook execute_playbook

# -------- Extras handling

extra_appname:
ifeq ($(wildcard $(FILES_D)/$(IMG)/apps/$(APP)/$(APP_F)),)
	$(info [Info] IMG ignorieren)
else
	@[[ -f $(FILES_D)/$(IMG)/apps/$(APP)/$(APP_F) ]] && make IMG=$(IMG) ENV=$(ENV) APP=$(APP) appname || (echo "[Info] No extra appname configured!")
endif

# -------- Instance handling

setup: PLAYBOOK=setup
setup: verify execute ending 

start: PLAYBOOK=start
start: verify execute ending

deploy: PLAYBOOK=deploy
deploy: verify execute ending 

stop: PLAYBOOK=stop
stop: verify execute ending

remove: DELETE=false
remove: EXTRAS += -e "clean_up=$(DELETE)"
remove: PLAYBOOK=remove
remove: verify execute ending

stats: PLAYBOOK=stats
stats: verify execute ending

status: PLAYBOOK=status
status: execute ending

# -------- APP handling

appname: APP=
appname: EXTRAS += -e "app_name=$(APP)"
appname: PLAYBOOK=$(IMG)/$(APP)
appname: verify execute ending

# -------- Environment handling

create: ENV=
create: PLAYBOOK=create
create: EXTRAS += -e "env_name=$(ENV)" -e "port=$(PORT)"
create: verify_var_env verify_port verify_var_img verify_extra execute ending

delete: ENV=
delete: DELETE=false
delete: PLAYBOOK=delete
delete: EXTRAS += -e "env_name=$(ENV)"
delete: EXTRAS += -e "clean_up=$(DELETE)"
delete: verify_var_env verify_var_img verify_extra execute ending

# -------- Image handling

build: PLAYBOOK=build
build: verify_var_img execute ending

filter_img:
	$(if $(IMG),$(info Using image: $(IMG)),)
	$(if $(IMG),$(eval EXTRA_IMG=-e "image=$(IMG)"),)
	$(if $(IMG),$(info EXTRA_IMG=$(EXTRA_IMG)),)

images: PLAYBOOK=images
images: filter_img execute ending

fetchall: PLAYBOOK=fetch
fetchall: $(DOCKER_IMAGES) ending

fetch: PLAYBOOK=fetch
fetch: set_img execute ending

removeimage: PLAYBOOK=removeimage
removeimage: verify_var_img execute ending

# -------- Wipe.out or debugging

wipeout: PLAYBOOK=wipeout
wipeout: execute ending

# -------- Infra handling

verify_infra:
	@test "$(INFRA)" && test -s $(CNFG_D)/infra/$(INFRA).txt || (echo "[Error] INFRA not set or INFRA txt not found! ($(CNFG_D)/infra/$(INFRA).txt)" && exit 1)


startup_doing: verify_infra
	$(info [Info] Startup '$(INFRA)' ...)
	@for l in `cat $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo "[Info]  Booting $$l ..."; \
		make IMG=$$l ENV=$(ENV) setup; \
		make IMG=$$l ENV=$(ENV) start; \
		echo; \
	done

startup: PLAYBOOK=startup
startup: verify_infra verify_var_env startup_doing ending


teardown_dowing: verify_infra
	$(info [Info] Teardown '$(INFRA)' ...----)
	@for l in `tac $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo "[Info] Shuting down $$l"; \
		make IMG=$$l ENV=$(ENV) stop; \
		echo; \
	done

teardown: verify_var_env verify_infra teardown_dowing ending


construct_doing:
	$(info [Info] Construct '$(INFRA)' ...)
	@for l in `cat $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo "[Info] Building $$l"; \
		make TAG=$$l build; \
		echo; \
	done

construct: verify_infra construct_doing do_images ending


cleanup_doing: 
	$(info [Info] Cleanup '$(INFRA)' ...)
	@for l in `cat $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo "[Info] Removing $$l"; \
		make IMG=$$l ENV=$(ENV) DELETE=$(DELETE) remove; \
		echo; \
	done

cleanup: DELETE=false
cleanup: verify_var_env verify_infra cleanup_doing ending


list:
	$(info [Info] List Infrastructures [$(CNFG_D)/infra/] ...)
	@pushd $(CNFG_D)/infra/ > /dev/null; ls -1 *.txt | cut -d _ -f 2 | cut -d . -f 1; popd > /dev/null
	$(info [Info])
	$(info [Info] List Application Stacks [$(CNFG_D)/envs/] ...)
	@pushd $(CNFG_D)/envs/ > /dev/null; ls -1dR */; popd > /dev/null
	$(info [Info])
	$(info [Info] List Environments in Application Stacks [$(CNFG_D)/envs/] ...)
	@pushd $(CNFG_D)/envs/ > /dev/null; ls -1dR **/*.json | cut -d / -f 2 | cut -d . -f 1 | sort -u; popd > /dev/null
	$(info [Info])
	$(info [Info] List Custom Docker Images [$(TAG_D)] ...)
	@pushd $(TAG_D) > /dev/null; ls -1dR */; popd > /dev/null
	$(info [Info])


ansible_cmd_check:
	@which ansible > /dev/null || (echo "[Error] ansible command not found!" && exit 1)

ansible_ping:
	$(info [Info] Ping docker host [$(DOCKERHOST)] ...)
	$(info [Info])
	@ansible -i $(INVENTORY) -m ping $(DOCKERHOST)

ping: ansible_cmd_check ansible_ping ending
