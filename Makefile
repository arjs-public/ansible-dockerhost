#
# Makefile -- combine some usefull stuff
#

.PHONY: help list status create delete ping
.PHONY: try develop test stage production
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
PB_D_B = $(BASE_D)/playbooks
PB_D = $(if $(IMG),$(PB_D_B)/$(IMG),$(PB_D_B))
CNFG_D = $(if $(IMG),$(BASE_D)/roles/$(IMG)/defaults,$(BASE_D)/roles/defaults)
TAG_D = $(BASE_D)/roles/files
FILES_D = $(BASE_D)/roles/files
TEMPLATES_D = $(BASE_D)/roles/templates
$(eval ANSIBLE_CFG=$(shell netstat -all | grep ' 6379 ' > /dev/null && echo redis || echo default))
# $(info [Info] Use ANSIBLE_CFG: $(ANSIBLE_CFG))
A_CFG = $(BASE_D)/configs/$(ANSIBLE_CFG).cfg
VPF_FILE = configs/.secrets/vpf.txt
# $(info [Info] Use A_CFG: $(A_CFG))
INVENTORY = $(BASE_D)/inventory/inventory

ifeq ($(wildcard $(CNFG_D)/envs/$(IMG)/$(ENV).json),)
 ifeq ($(wildcard $(CNFG_D)/envs/$(IMG)/$(NAME)/$(ENV).json),)
 CONFIGS =
 else
 CONFIGS = -e "@$(CNFG_D)/envs/$(IMG)/$(NAME)/$(ENV).json"
 endif
else
 CONFIGS = -e "@$(CNFG_D)/envs/$(IMG)/$(ENV).json"
endif
ifneq ($(wildcard $(VPF_FILE)),)
 CONFIGS += --vault-password-file ./$(VPF_FILE)
endif

# --------- Rules

help:
	$(info [Info] -- Help ---------)
	$(info [Info] )
	$(info [Info] * make IMG=<image to use> *? [ENV=<environment> *?] [NAME=<appname> 6*?] [EXTRAS=<ansible-playbook params>] setup)
	$(info [Info] * make IMG=<image to use> *? [ENV=<environment> *?] [NAME=<appname> 6*?] [EXTRAS=<ansible-playbook params>] boot)
	$(info [Info] * make IMG=<image to use> *? [ENV=<environment> *?] [NAME=<appname> 6*?] shutdown)
	$(info [Info] * make IMG=<image to use> *? [ENV=<environment> *?] [NAME=<appname> 6*?] [DELETE=true|*false ***?] destroy)
	$(info [Info] * make IMG=<image to use> *? [ENV=<environment> *?] [NAME=<appname> 6*?] stats)
	$(info [Info] * make INFRA=<infra name from list> [ENV=<environment> *?] startup)
	$(info [Info] * make INFRA=<infra name from list> teardown)
	$(info [Info] * make INFRA=<infra name from list> construct)
	$(info [Info] * make INFRA=<infra name from list> [DELETE=true|*false ***?] cleanup)
	$(info [Info] * make ENV=<Environment name> *? [IMG=<appgroup> 5*?] [NAME=<appname> 6*?] (PORT=<Port extension to use> **? create | [DELETE=true ***?] delete))
	$(info [Info] * make IMG=<image to use> build)
	$(info [Info] * make IMG=<image from dockerhub> fetch)
	$(info [Info] * make IMG=<image from images> *? destroyi)
	$(info [Info] * make ping | status | images | list | wipeout ****?)
	$(info [Info] )
	$(info [Info] *? see 'make list' output for available options; default: ENV = develop)
	$(info [Info] **? Port extension to use with normal prefix 80 or db prefix 90; e.g. normal (80) + extenison (85) = port (8085))
	$(info [Info] ***? Very dangerous, since deletes all associated folders on 'dockerhost')
	$(info [Info] ****? Very dangerous, since it kills all docker containers on 'dockerhost')
	$(info [Info] *****? IMG empty means ENV Environment in all Applications; IMG set, means ENV Environment for specific Application)
	$(info [Info] ******? NAME needed for special image)
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

# -------- Verify handling

verify_var_img:
	@test "$(IMG)" || (echo "[Error] IMG not set!" && exit 1)
	$(info [Info] Use image: $(IMG))
	@test "$(IMG)" && test -d "$(CNFG_D)/envs/" || (echo "[Error] IMG not set or IMG folder not found! ($(CNFG_D)/envs/)" && exit 1)
	$(eval APPIMG=-e "image=$(IMG)")
	$(info [Info] Use image extra: $(APPIMG))
	$(info [Info])

verify_var_name:
ifndef NAME
	@test "$(ENV)" && test -s $(CNFG_D)/envs/$(IMG)/$(ENV).json || (echo "[Error] ENV not set or ENV json not found! ($(CNFG_D)/envs/$(IMG)/$(ENV).json))" && exit 1)
else
	$(info [Info] Use application name: $(NAME))
	@test "$(NAME)" && test "$(ENV)" && test -s $(CNFG_D)/envs/$(NAME)/$(ENV).json || (echo "[Error] NAME or ENV not set or IMG/ENV json not found! ($(CNFG_D)/envs/$(IMG)/$(NAME)/$(ENV).json))" && exit 1)
	$(eval APNEXTRA=-e "app_name=$(NAME)")
	$(info [Info] Use application name extra: $(APNEXTRA))
endif
	$(info [Info])

verify_var_env:
	$(if $(ENV),,$(call try))
	@test "$(ENV)" || (echo "[Error] ENV not set!" && exit 1)
	$(info [Info] Use environment: $(ENV))
	$(info [Info] Use environment extra: $(ENVNAME))
	$(info [Info])

verify_port:
	@test "$(PORT)" || (echo "[Error] PORT not set!" && exit 1)
	$(info [Info] Use port: $(PORT))
	$(info [Info])

verify_extra1:
ifdef NAME
	$(eval APNEXTRA=-e "app_name=$(NAME)")
endif

verify: verify_var_img verify_var_name verify_var_name

# -------- Playbook handling

set_playbook:
	$(if $(PLAYBOOK),,$(eval PLAYBOOK=main))
	$(eval PLAYBOOKPATH = $(if $(wildcard $(PB_D)/$(PLAYBOOK).yml),$(PB_D)/$(PLAYBOOK).yml,$(PB_D_B)/$(PLAYBOOK).yml))
	$(info [Info] Using Playbook: $(PLAYBOOKPATH) ...)	

verify_playbook:
	$(info [Info] Verify playbook $(PLAYBOOKPATH) ...)
	@test -f $(PLAYBOOKPATH) && echo "[Info] Found playbook $(PLAYBOOKPATH) ..." || (echo "[Error] No playbook found!" && exit 1)

execute_playbook: 
	$(info [Info])
	$(info [Info] Execute playbook '$(PLAYBOOK)' ...)

execute: set_playbook verify_playbook execute_playbook
	$(info [Info])

ifeq ($(wildcard $(A_CFG)),)
	@echo "[Info] Not executed: ansible-playbook $(PLAYBOOKPATH) $(CONFIGS) $(APPIMG) $(ENVNAME) $(EXTRAS) $(APNEXTRA)
	exit 1
else
	@ANSIBLE_CONFIG=$(A_CFG) ansible-playbook $(PLAYBOOKPATH) $(CONFIGS) $(APPIMG) $(ENVNAME) $(EXTRAS) $(APNEXTRA)
endif
	$(info [Info])

# -------- Extras handling

extra_config:
ifeq ($(wildcard $(TEMPLATES_D)/$(IMG)/$(CONFIG_F)),)
	$(info [Info] Config ignorieren)
else
	@[[ -f $(TEMPLATES_D)/$(IMG)/$(CONFIG_F) ]] && make IMG=$(IMG) ENV=$(ENV) configs || (echo "[Info] No extra files available!")
endif

extra_plugins:
ifeq ($(wildcard $(FILES_D)/$(IMG)/$(PLUGIN_F)),)
	$(info [Info] Plugins ignorieren)
else
	@[[ -f $(FILES_D)/$(IMG)/$(PLUGIN_F) ]] && make IMG=$(IMG) ENV=$(ENV) plugins || (echo "[Info] No extra plugins configured!")
endif

extra_appname:
ifeq ($(wildcard $(FILES_D)/$(IMG)/apps/$(NAME)/$(APP_F)),)
	$(info [Info] IMG ignorieren)
else
	@[[ -f $(FILES_D)/$(IMG)/apps/$(NAME)/$(APP_F) ]] && make IMG=$(IMG) ENV=$(ENV) NAME=$(NAME) appname || (echo "[Info] No extra appname configured!")
endif

extras: extra_config extra_plugins extra_appname
	$(info [Info])

# -------- Environment handling

define try =
	$(eval ENV=try)
	$(info [Info] Use environment: $(ENV))
	$(eval ENVNAME=-e "env_name=$(ENV)")
	$(info [Info] Use environment extra: $(ENVNAME))
	$(info [Info])
	@true
endef

try:
	$(call try)

develop:
	$(eval ENV=develop)
	$(info [Info] Use environment: $(ENV))
	$(eval ENVNAME=-e "env_name=$(ENV)")
	$(info [Info] Use environment extra: $(ENVNAME))
	@true

# -------- Instance handling

setup: PLAYBOOK=setup
setup: verify extras execute ending 

boot: PLAYBOOK=boot
boot: HOSTNAME=$(ENV).$(NAME)
boot: EXTRAS += -e "host=$(HOSTNAME)"
boot: verify execute do_stats do_status ending

shutdown: PLAYBOOK=shutdown
shutdown: verify execute do_stats do_status ending

destroy_do: execute
	$(info [Info] Do Destroy ...)

destroy: DELETE=false
destroy: EXTRAS += -e "clean_up=$(DELETE)"
destroy: PLAYBOOK=destroy
destroy: verify do_stats destroy_do do_status ending

do_stats:
	@make IMG=$(IMG) ENV=$(ENV) NAME=$(NAME) stats

stats: PLAYBOOK=stats
stats: verify execute ending

do_status:
	@make IMG=$(IMG) ENV=$(ENV) NAME=$(NAME) status

status: PLAYBOOK=status
status: verify_img verify_var_env execute ending

# -------- Jenkins handling

configs: PLAYBOOK=jenkins/configs
configs: verify execute ending

plugins: PLAYBOOK=jenkins/plugins
plugins: verify execute ending

# -------- IMG handling

appname: NAME=
appname: EXTRAS += -e "app_name=$(NAME)"
appname: PLAYBOOK=$(IMG)/appname
appname: verify execute ending
# -------- Environment handling

create: ENV=
create: PLAYBOOK=create
create: EXTRAS += -e "env_name=$(ENV)" -e "port=$(PORT)"
create: verify_var_env verify_port verify_img verify_extra execute ending

delete: ENV=
delete: DELETE=false
delete: PLAYBOOK=delete
delete: EXTRAS += -e "env_name=$(ENV)"
delete: EXTRAS += -e "clean_up=$(DELETE)"
delete: verify_var_env verify_img verify_extra execute ending

# -------- Image handling

build: PLAYBOOK=build
build: verify_var_img execute ending


filter_img:
	$(info IMG=$(IMG))
	$(eval APPIMG=-e "image=$(IMG)")
	$(info APPIMG=$(APPIMG))

do_images: 
	@make images

images: PLAYBOOK=images
images: filter_img execute ending

fetch: PLAYBOOK=fetch
fetch: verify_img execute ending

destroyi: PLAYBOOK=destroyi
destroyi: verify_img execute ending

# -------- Wipe.out or debugging

wipeout: PLAYBOOK=wipeout
wipeout: execute do_status ending

# -------- Infra handling

verify_infra:
	@test "$(INFRA)" && test -s $(CNFG_D)/infra/$(INFRA).txt || (echo "[Error] INFRA not set or INFRA txt not found! ($(CNFG_D)/infra/$(INFRA).txt)" && exit 1)


startup_doing: verify_infra
	$(info [Info] Startup '$(INFRA)' ...)
	@for l in `cat $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo "[Info]  Booting $$l ..."; \
		make IMG=$$l ENV=$(ENV) setup; \
		make IMG=$$l ENV=$(ENV) boot; \
		echo; \
	done

startup: PLAYBOOK=startup
startup: verify_infra verify_var_env startup_doing do_status ending


teardown_dowing: verify_infra
	$(info [Info] Teardown '$(INFRA)' ...----)
	@for l in `tac $(CNFG_D)/infra/$(INFRA).txt`; \
	do \
		echo "[Info] Shuting down $$l"; \
		make IMG=$$l ENV=$(ENV) shutdown; \
		echo; \
	done

teardown: verify_var_env verify_infra teardown_dowing do_status ending


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
		make IMG=$$l ENV=$(ENV) DELETE=$(DELETE) destroy; \
		echo; \
	done

cleanup: DELETE=false
cleanup: verify_var_env verify_infra cleanup_doing do_status ending


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
