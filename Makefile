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
	$(info [Info] * make <image> build)
	$(info [Info] * make <image> *? removeimage)
	$(info [Info] * make hub.<image from dockerhub> fetch)
	$(info [Info] * make fetchall)
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

# -------- Playbook handling

define SET_EXTRA_VARS
	$(if $(wildcard $(VPF_FILE)),$(eval VPF=--vault-password-file ./$(VPF_FILE)),$(eval VPF=))
    $(info [Info] Using vpf: $(VPF))
	$(if $(wildcard $(CNFG_D)/envs/$(APP)/$(ENV).json),
		$(eval CONFIGS=-e "@$(CNFG_D)/envs/$(APP)/$(ENV).json"),
		$(if $(wildcard $(CNFG_D)/envs/$(ENV).json),
			$(eval CONFIGS=-e "@$(CNFG_D)/envs/$(ENV).json"),
			$(eval CONFIGS=)
		)
	)
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
	$(error [Info] Not executed: ansible-playbook $(PLAYBOOKPATH) $(VPF) $(CONFIGS) $(EXTRA_IMG) $(EXTRA_ENV) $(EXTRA_APP) $(EXTRAS))
endef

define EXECUTE_PLAYBOOK
	$(info [Info] Execute playbook '$(PLAYBOOK)' ...)
	$(info [Info])
	@ANSIBLE_CONFIG=$(A_CFG) ansible-playbook $(PLAYBOOKPATH) $(VPF) $(CONFIGS) $(EXTRA_IMG) $(EXTRA_ENV) $(EXTRA_APP) $(EXTRAS)
endef

define EXECUTE
	$(eval IMG=$(subst +,:,$(subst hub.,,$(1))))
	$(info [Info] Processing $(IMG))
	$(call SET_EXTRA_IMG)
	$(if $(wildcard $(A_CFG)),$(call EXECUTE_PLAYBOOK),$(call EXECUTE_ERROR))
endef

set_extra_vars:
	$(call SET_EXTRA_VARS)

set_playbook:
	$(call SET_PLAYBOOK)

verify_playbook:
	$(info [Info] )
	$(call VERIFY_PLAYBOOK)

execute_playbook: 
	$(if $(wildcard $(A_CFG)),$(call EXECUTE_PLAYBOOK),$(call EXECUTE_ERROR))

execute: set_extra_vars set_playbook verify_playbook execute_playbook

# -------- Instance handling

setup: PLAYBOOK=setup
setup: verify_var_env verify_var_app verify_var_img execute ending 

start: PLAYBOOK=start
start: verify_var_env verify_var_app verify_var_img execute ending

deploy: PLAYBOOK=deploy
deploy: verify_var_env verify_var_app verify_var_img execute ending 

stop: PLAYBOOK=stop
stop: verify_var_env verify_var_app verify_var_img execute ending

remove: DELETE=false
remove: EXTRAS += -e "clean_up=$(DELETE)"
remove: PLAYBOOK=remove
remove: verify_var_env verify_var_app verify_var_img execute ending

stats: PLAYBOOK=stats
stats: verify_var_env verify_var_app verify_var_img execute ending

status: PLAYBOOK=status
status: execute ending

# -------- APP handling

#appname: APP=
#appname: EXTRAS += -e "app_name=$(APP)"
#appname: PLAYBOOK=$(IMG)/$(APP)
#appname: verify execute ending

# -------- Environment handling

create: ENV=
create: PLAYBOOK=create
create: EXTRAS += -e "port=$(PORT)"
create: verify_var_env verify_var_app verify_var_img verify_port execute ending

delete: ENV=
delete: DELETE=false
delete: PLAYBOOK=delete
delete: EXTRAS += -e "clean_up=$(DELETE)"
delete: verify_var_env verify_var_app verify_var_img execute ending

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
fetchall: 
	$(call SET_PLAYBOOK)
	$(call VERIFY_PLAYBOOK)
	$(foreach hub,$(DOCKER_IMAGES),$(info $(hub)))
	$(foreach hub,$(DOCKER_IMAGES),$(call EXECUTE,$(hub)))
	@true

fetch: PLAYBOOK=fetch
fetch: verify_var_img execute ending

removeimage: PLAYBOOK=removeimage
removeimage: verify_var_img execute ending

# -------- Wipe.out

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
	$(eval CNFG_D=$(BASE_D)/vars)
	$(info [Info] List Infrastructures [infra/] ...)
	$(eval output=$(shell pushd $(CNFG_D)/infra/ > /dev/null; ls -1 *.txt | cut -d _ -f 2 | cut -d . -f 1; popd > /dev/null))
	$(foreach out,$(output),$(info [Info] - $(out)))
	$(info [Info])
	$(info [Info] List Application Stack Images [roles/] ...)
	$(eval output=$(shell pushd $(BASE_D)/roles/ > /dev/null; ls -1dR */ | grep -vE "_template_|common"; popd > /dev/null))
	$(foreach out,$(output),$(info [Info] - $(out)))
	$(info [Info])
	$(info [Info] List Environments in Application Stacks [envs/] ...)
	$(eval output=$(shell pushd $(BASE_D)/roles/ > /dev/null; ls -1R */defaults/envs/*.json | cut -d / -f 1,4 | cut -d . -f 1 | sort -u; popd > /dev/null))
	$(foreach out,$(output),$(info [Info] - $(out)))
	$(eval output=$(shell pushd $(BASE_D)/roles/ > /dev/null; ls -1R */defaults/envs/**/*.json | cut -d / -f 1,4,5 | sed "s/.json//" | sort -u; popd > /dev/null))
	$(foreach out,$(output),$(info [Info] - $(out)))
	$(info [Info])
	@true


ansible_cmd_check:
	@which ansible > /dev/null || (echo "[Error] ansible command not found!" && exit 1)

ansible_ping:
	$(info [Info] Ping docker host [$(DOCKERHOST)] ...)
	$(info [Info])
	@ansible -i $(INVENTORY) -m ping $(DOCKERHOST)

ping: ansible_cmd_check ansible_ping ending
