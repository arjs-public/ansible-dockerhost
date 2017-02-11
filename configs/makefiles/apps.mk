.PHONY: *


define APP_INFO
	$(info [Info] Use application name: $(APP))
	$(info [Info] Use application name extra: $(EXTRA_APP))
	$(info [Info] Use extra vars: $(EXTRAS))
	$(info [Info])
	@true
endef

define SET_APP_NAME
	$(eval APP=$(1))
	$(if $(APP),,$(error [Error] APP not set!))
	$(eval EXTRA_APP=-e "app_name=$(APP)")
	@true
endef

define SET_APP_ARTIFACT_INFO
	$(eval ARTIFACT_PATH=$(shell echo $(APP) | tr '.' '\n' | tac | tr '\n' '/'))
	$(eval ARTIFACT_SPEC=libs-snapshot-local/$(2))
	$(eval ARTIFACT_NAME=$(3))
	$(eval EXTRAS += -e "artifact_path=$(ARTIFACT_PATH)")
	$(eval EXTRAS += -e "artifact_name=$(ARTIFACT_NAME)")
	$(eval EXTRAS += -e "artifact_spec=$(ARTIFACT_SPEC)")
	@true
endef


verify_var_app:
	$(if $(APP),,$(error [Error] APP not set!))


jenkins:
	$(call SET_APP_NAME,$@)
	$(call APP_INFO)
