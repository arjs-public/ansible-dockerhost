#
# Makefile -- combine some usefull stuff
#

.PHONY: help list status create delete ping
.PHONY: boot shutdown destroy stats destroy plugins configs setup
.PHONY: images fetch destroyi
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
PB_D = $(BASE_D)/playbooks
TAG_D = $(BASE_D)/roles/files
CNFG_D = $(BASE_D)/roles/defaults
FILES_D = $(BASE_D)/roles/files
TEMPLATES_D = $(BASE_D)/roles/templates
$(eval ANSIBLE_CFG=$(shell netstat -all | grep 6379 > /dev/null && echo redis || echo default))
# $(info [Info] Use ANSIBLE_CFG: $(ANSIBLE_CFG))
A_CFG = $(BASE_D)/configs/$(ANSIBLE_CFG).cfg
VPF_FILE = configs/.secrets/vpf.txt
# $(info [Info] Use A_CFG: $(A_CFG))
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
	$(info [Info] -- Help ---------)
	$(info [Info] )
	$(info [Info] * make APP=<app folder> *? [ENV=<environment> *?] [APN=<appname> 6*?] [EXTRAS=<ansible-playbook params>] setup)
	$(info [Info] * make APP=<app folder> *? [ENV=<environment> *?] [APN=<appname> 6*?] [EXTRAS=<ansible-playbook params>] boot)
	$(info [Info] * make APP=<app folder> *? [ENV=<environment> *?] [APN=<appname> 6*?] shutdown)
	$(info [Info] * make APP=<app folder> *? [ENV=<environment> *?] [APN=<appname> 6*?] [DELETE=true|*false ***?] destroy)
	$(info [Info] * make APP=<app folder> *? [ENV=<environment> *?] [APN=<appname> 6*?] stats)
	$(info [Info] * make INFRA=<infra name from list> [ENV=<environment> *?] startup)
	$(info [Info] * make INFRA=<infra name from list> teardown)
	$(info [Info] * make INFRA=<infra name from list> construct)
	$(info [Info] * make INFRA=<infra name from list> [DELETE=true|*false ***?] cleanup)
	$(info [Info] * make ENV=<Environment name> *? [APP=<appgroup> 5*?] [APN=<appname> 6*?] (PORT=<Port extension to use> **? create | [DELETE=true ***?] delete))
	$(info [Info] * make TAG=<Dockerfile folder> build)
	$(info [Info] * make IMG=<image from dockerhub> fetch)
	$(info [Info] * make IMG=<image from images> *? destroyi)
	$(info [Info] * make ping | status | images | list | wipeout ****?)
	$(info [Info] )
	$(info [Info] *? see 'make list' output for available options; default: ENV = develop)
	$(info [Info] **? Port extension to use with normal prefix 80 or db prefix 90; e.g. normal (80) + extenison (85) = port (8085))
	$(info [Info] ***? Very dangerous, since deletes all associated folders on 'dockerhost')
	$(info [Info] ****? Very dangerous, since it kills all docker containers on 'dockerhost')
	$(info [Info] *****? APP empty means ENV Environment in all Applications; APP set, means ENV Environment for specific Application)
	$(info [Info] ******? APN needed for app image)
	$(info [Info] )
	$(info [Info] -- Defaults ---------)
	$(info [Info] * ENV = $(ENV))
	$(info [Info] * BASE_D = $(BASE_D))
	$(info [Info] * PB_D = $(PB_D))
	$(info [Info] * TAG_D = $(TAG_D))
	$(info [Info] * CNFG_D = $(CNFG_D))
	$(info [Info] * FILES_D = $(FILES_D))
	$(info [Info] * A_CFG = $(A_CFG))
	$(info [Info] )

# -------- Helpers handling

starting:
	$(info [Info])
	$(info [Info] Starting $(PLAYBOOK))
	
ending:
	$(info [Info] Finsihed $(PLAYBOOK))
	$(info [Info])

# -------- Playbook handling

verify_playbook:
	$(info [Info] Verify playbook $(PB_D)/$(PLAYBOOK).yml ...)
	$(eval PLAYBOOKPATH=$(PB_D)/$(PLAYBOOK).yml)
	@test -f $(PLAYBOOKPATH) && echo "[Info] Found playbook $(PB_D)/$(PLAYBOOK).yml ..." || (echo "[Error] No playbook found!" && exit 1)

execute: verify_playbook
	$(info [Info])
	$(info [Info] Execute playbook '$(PLAYBOOK)' ...)

ifeq ($(wildcard $(A_CFG)),)
	@echo "[Info] Not executed: ansible-playbook $(PLAYBOOKPATH) $(APPIMG) $(ENVNAME) $(CONFIGS) $(EXTRAS)
	exit 1
else
	@ANSIBLE_CONFIG=$(A_CFG) ansible-playbook $(PLAYBOOKPATH) $(APPIMG) $(ENVNAME) $(CONFIGS) $(EXTRAS) $(APNEXTRA)
endif
	$(info [Info])

# -------- Verify handling

verify_var_app:
	$(info [Info])
	$(info [Info] Use application: $(APP))
	@test "$(APP)" && test -d "$(CNFG_D)/envs/$(APP)/" || (echo "[Error] APP not set or APP folder not found! ($(CNFG_D)/envs/$(APP)/)" && exit 1)

verify_var_apn:
ifndef APN
	@test "$(ENV)" && test -s $(CNFG_D)/envs/$(APP)/$(ENV).json || (echo "[Error] ENV not set or ENV json not found! ($(CNFG_D)/envs/$(APP)/$(ENV).json))" && exit 1)
else
	$(info [Info] Use application name: $(APN))
	@test "$(APN)" && test "$(ENV)" && test -s $(CNFG_D)/envs/$(APP)/$(APN)/$(ENV).json || (echo "[Error] APN or ENV not set or APN/ENV json not found! ($(CNFG_D)/envs/$(APP)/$(APN)/$(ENV).json))" && exit 1)
	$(eval APNEXTRA=-e "app_name=$(APN)")
	$(info [Info] Use application name extra: $(APNEXTRA))
endif
	$(info [Info] Use environment: $(ENV))

verify: verify_var_app verify_var_apn verify_app
	$(info [Info])

# -------- Extras handling

extra_config:
ifeq ($(wildcard $(TEMPLATES_D)/$(APP)/$(CONFIG_F)),)
	$(info [Info] Config ignorieren)
else
	@[[ -f $(TEMPLATES_D)/$(APP)/$(CONFIG_F) ]] && make APP=$(APP) ENV=$(ENV) configs || (echo "[Info] No extra files available!")
endif

extra_plugins:
ifeq ($(wildcard $(FILES_D)/$(APP)/$(PLUGIN_F)),)
	$(info [Info] Plugins ignorieren)
else
	@[[ -f $(FILES_D)/$(APP)/$(PLUGIN_F) ]] && make APP=$(APP) ENV=$(ENV) plugins || (echo "[Info] No extra plugins configured!")
endif

extra_appname:
ifeq ($(wildcard $(FILES_D)/$(APP)/apps/$(APN)/$(APP_F)),)
	$(info [Info] APP ignorieren)
else
	@[[ -f $(FILES_D)/$(APP)/apps/$(APN)/$(APP_F) ]] && make APP=$(APP) ENV=$(ENV) APN=$(APN) appname || (echo "[Info] No extra appname configured!")
endif

extras: extra_config extra_plugins extra_appname
	$(info [Info])

# -------- Instance handling

setup: PLAYBOOK=setup
setup: starting verify extras execute ending 

boot: PLAYBOOK=boot
boot: starting verify execute do_stats do_status ending

shutdown: PLAYBOOK=shutdown
shutdown: starting verify execute do_stats do_status ending

destroy_do: execute
	$(info [Info] Do Destroy ...)

destroy: DELETE=false
destroy: EXTRAS += -e "clean_up=$(DELETE)"
destroy: PLAYBOOK=destroy
destroy: starting verify do_stats destroy_do do_status ending

do_stats:
	@make APP=$(APP) ENV=$(ENV) APN=$(APN) stats

stats: PLAYBOOK=stats
stats: starting verify execute ending

do_status:
	@make APP=$(APP) ENV=$(ENV) APN=$(APN) status

status: PLAYBOOK=status
status: starting verify_app verify_env execute ending

# -------- Jenkins handling

configs: PLAYBOOK=jenkins/configs
configs: starting verify execute ending

plugins: PLAYBOOK=jenkins/plugins
plugins: starting verify execute ending

# -------- App handling

appname: APN=
appname: EXTRAS += -e "appname=$(APN)"
appname: PLAYBOOK=$(APP)/appname
appname: starting verify execute ending

# -------- Environment handling

verify_env:
ifndef ENV
	$(eval ENV=develop")
endif
	@test "$(ENV)" || (echo "[Error] ENV not set!" && exit 1)
	$(info [Info] Use environment: $(ENV))
	$(eval ENVNAME=-e "env_name=$(ENV)")
	$(info [Info] Use env extra: $(ENVNAME))

verify_port:
	@test "$(PORT)" || (echo "[Error] PORT not set!" && exit 1)
	$(info [Info] Use port: $(PORT))

verify_app:
	$(eval APPIMG=-e "image=$(APP)")
	$(info [Info] Use image: $(APPIMG))

verify_extra:
ifdef APN
	$(eval APNEXTRA=-e "appname=$(APN)")
endif

create: ENV=
create: PLAYBOOK=create
create: EXTRAS += -e "env_name=$(ENV)" -e "port=$(PORT)"
create: starting verify_env verify_port verify_app verify_extra execute ending

delete: ENV=
delete: DELETE=false
delete: PLAYBOOK=delete
delete: EXTRAS += -e "env_name=$(ENV)"
delete: EXTRAS += -e "clean_up=$(DELETE)"
delete: starting verify_env verify_app verify_extra execute ending

# -------- Image handling

verify_tag:
	$(eval APP=$(TAG))
	@test "$(APP)" && test -d $(TAG_D)/$(TAG)/ || (echo "[Error] TAG not set or TAG folder not found! ($(TAG_D)/$(TAG)/)" && exit 1)
	$(eval APPIMG=-e "image=$(APP)")

build: PLAYBOOK=build
build: starting verify_tag execute ending


filter_img:
	$(info IMG=$(IMG))
	$(eval APPIMG=-e "image=$(IMG)")
	$(info APPIMG=$(APPIMG))

do_images: 
	@make images

images: PLAYBOOK=images
images: starting filter_img execute ending


verify_img:
	@test "$(IMG)" || (echo "[Error] IMG not set!" && exit 1)
	$(eval APPIMG=-e "image=$(IMG)")

fetch: PLAYBOOK=fetch
fetch: starting verify_img execute ending

destroyi: PLAYBOOK=destroyi
destroyi: starting verify_img execute ending

# -------- Wipe.out or debugging

wipeout: PLAYBOOK=wipeout
wipeout: starting execute do_status ending

# -------- Infra handling

verify_infra:
	@test "$(INFRA)" && test -s $(CNFG_D)/infra/$(INFRA).txt || (echo "[Error] INFRA not set or INFRA txt not found! ($(CNFG_D)/infra/$(INFRA).txt)" && exit 1)


startup_doing: verify_infra
	$(info [Info] Startup '$(INFRA)' ...)
	@for l in `cat $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo "[Info]  Booting $$l ..."; \
		make APP=$$l ENV=$(ENV) boot; \
		echo; \
	done

startup: starting verify_infra startup_doing do_status ending


teardown_dowing: verify_infra
	$(info [Info] Teardown '$(INFRA)' ...----)
	@for l in `tac $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo "[Info] Shuting down $$l"; \
		make APP=$$l ENV=$(ENV) shutdown; \
		echo; \
	done

teardown: starting verify_infra teardown_dowing do_status ending


construct_doing:
	$(info [Info] Construct '$(INFRA)' ...)
	@for l in `cat $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo "[Info] Building $$l"; \
		make TAG=$$l build; \
		echo; \
	done

construct: starting verify_infra construct_doing do_images ending


cleanup_doing: 
	$(info [Info] Cleanup '$(INFRA)' ...)
	@for l in `cat $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo "[Info] Removing $$l"; \
		make APP=$$l ENV=$(ENV) DELETE=$(DELETE) destroy; \
		echo; \
	done

cleanup: DELETE=false
cleanup: starting verify_infra cleanup_doing do_status ending


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
	
ping: ansible_cmd_check
	$(info [Info] ping docker host [$(DOCKERHOST)] ...)
	@ansible -i $(INVENTORY) -m ping $(DOCKERHOST)
