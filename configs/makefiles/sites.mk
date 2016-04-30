.PHONY: *

define SITE_INFO
	$(info [Info] Use application name: $(APP))
	$(info [Info] Use application name extra: $(EXTRA_APP))
	$(info [Info] Use extra vars: $(EXTRAS))
	$(info [Info])
endef

define SET_EXTRA_SITE
	$(eval APP=$(1))
	$(if $(APP),,$(error [Error] APP not set!))
	$(eval ARTIFACT_PATH=$(shell echo $(APP) | tr '.' '\n' | tac | tr '\n' '/'))
	$(eval EXTRA_APP=-e "app_name=$(APP)")
	$(eval EXTRAS += -e "artifact_path=$(ARTIFACT_PATH)")
	$(call SITE_INFO)
	@true
endef

v2.arjs.net:
	$(call SET_EXTRA_SITE,$@)
