.PHONY: *

DOCKER_IMAGES = busybox ubuntu tomcat nginx redis jenkins python python+2.7 python+2.7-onbuild

define SET_APPIMG
	@test "$(IMG)" || (echo "[Error] IMG not set!" && exit 1)
	$(info [Info] Use image: $(IMG))
	$(eval APPIMG=-e "image=$(IMG)")
	$(info [Info] Use image extra: $(APPIMG))
	$(info [Info])
endef
	
define SET_APPIMG_ENV
	@test "$(CNFG_D)" || (echo "[Error] CNFG_D not set!" && exit 1)
	@test -d "$(CNFG_D)/envs/" || (echo "[Error] IMG/ENV folder not found! ($(CNFG_D)/envs/)" && exit 1)
	$(call SET_APPIMG)
endef

$(DOCKER_IMAGES):
	$(info [Info] Processing $(subst +,:,$@))
	$(eval IMG=$(subst +,:,$@))
	$(call SET_APPIMG)
	$(call EXECUTE)

set_img: 
	$(call SET_APPIMG)

site:
	$(eval IMG=site)
	$(call SET_APPIMG_ENV)
	
apps:
	$(eval IMG=apps)
	$(call SET_APPIMG_ENV)
	
cictl:
	$(eval IMG=cictl)
	$(call SET_APPIMG_ENV)
	
cidb:
	$(eval IMG=cidb)
	$(call SET_APPIMG_ENV)
	
simple:
	$(eval IMG=simple)
	$(call SET_APPIMG_ENV)
	
base:
	$(eval IMG=base)
	$(call SET_APPIMG_ENV)
