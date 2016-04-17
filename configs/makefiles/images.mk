.PHONY: *

define SET_APPIMG
	@test "$(IMG)" || (echo "[Error] IMG not set!" && exit 1)
	$(info [Info] Use image: $(IMG))
	$(eval APPIMG=-e "image=$(IMG)")
	$(info [Info] Use image extra: $(APPIMG))
	$(info [Info])
endef

set_img:
	$(call SET_APPIMG)
	
define SET_APPIMG_ENV
	@test "$(CNFG_D)" || (echo "[Error] CNFG_D not set!" && exit 1)
	@test -d "$(CNFG_D)/envs/" || (echo "[Error] IMG/ENV folder not found! ($(CNFG_D)/envs/)" && exit 1)
	$(call SET_APPIMG)
endef

site:
	$(eval IMG=site)
	$(call SET_APPIMG_ENV)
	
cictl:
	@echo CICTL
	
base:
	@echo BASE
	
apps:
	@echo APPS
