.PHONY: *


define SET_APP_NAME
	$(eval APP=$(1))
	$(if $(APP),$(info [Info] Use app name: $(APP)),$(error [Error] APP not set!))
	$(eval EXTRA_APP=-e "app_name=$(APP)")
	$(info [Info] Use app name extra: $(EXTRA_APP))
	$(info [Info])
	@true
endef

define SET_APP_ARTIFACT_INFO
	$(eval ENV=$(1))
	$(eval ARTIFACT_SPEC=libs-snapshot-local/$(2))
	$(eval ARTIFACT_NAME=$(3))
	$(call ENV_COMMON)
endef


verify_var_app:
	$(if $(APP),,$(error [Error] APP not set!))


jenkins: 
	$(call SET_APP_NAME,$@)

site:
	$(call SET_APP_NAME,$@)
	$(call SET_APP_ARTIFACT_INFO,$@,sites,ci/current.tgz)
