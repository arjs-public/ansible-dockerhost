.PHONY: *

site:
	$(eval IMG=site)
	@test "$(IMG)" || (echo "[Error] IMG not set!" && exit 1)
	$(info [Info] Use image: $(IMG))
	@test "$(IMG)" && test -d "$(CNFG_D)/envs/" || (echo "[Error] IMG not set or IMG folder not found! ($(CNFG_D)/envs/)" && exit 1)
	$(eval APPIMG=-e "image=$(IMG)")
	$(info [Info] Use image extra: $(APPIMG))
	$(info [Info])
	
cictl:
	@echo CICTL
	
base:
	@echo BASE
	
apps:
	@echo APPS
