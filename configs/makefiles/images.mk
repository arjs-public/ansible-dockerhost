.PHONY: *

DOCKER_IMAGES = hub.busybox \
	hub.ubuntu \
	hub.tomcat \
	hub.nginx \
	hub.redis \
	hub.mariadb \
	hub.jenkins \
	hub.python \
	hub.python+2.7 \
	hub.python+2.7-onbuild


define SET_EXTRA_IMG
	$(if $(IMG),$(info [Info] Use image name: $(IMG)),$(error [Error] IMG not set!))
	$(eval EXTRA_IMG=-e "image=$(IMG)")
	$(info [Info] Use image name extra: $(EXTRA_IMG))
	$(info [Info])
	@true
endef
	
define SET_EXTRA_IMG_ENV
	$(eval CNFG_D=$(if $(IMG),$(BASE_D)/roles/$(IMG)/defaults,$(BASE_D)/vars/roles))
	@test "$(CNFG_D)" || (echo "[Error] CNFG_D not set!" && exit 1)
	@test -d "$(CNFG_D)/envs/" || (echo "[Error] IMG/ENV folder not found! ($(CNFG_D)/envs/)" && exit 1)
	$(call SET_EXTRA_IMG)
endef

$(DOCKER_IMAGES):
	$(eval IMG=$(basename $(subst +,:,$(subst .,,$(suffix $@)))))
	$(info [Info] Processing $(IMG))
	$(call SET_EXTRA_IMG)


verify_var_img:
	$(if $(IMG),,$(error [Error] IMG not set!))

set_img:
	$(call SET_EXTRA_IMG)

site:
	$(eval IMG=site)
	$(call SET_EXTRA_IMG_ENV)
	
apps:
	$(eval IMG=apps)
	$(call SET_EXTRA_IMG_ENV)
	
cictl:
	$(eval IMG=cictl)
	$(call SET_EXTRA_IMG_ENV)
	
cidb:
	$(eval IMG=cidb)
	$(call SET_EXTRA_IMG_ENV)
	
simple:
	$(eval IMG=simple)
	$(call SET_EXTRA_IMG_ENV)
	
base:
	$(eval IMG=base)
	$(call SET_EXTRA_IMG_ENV)
