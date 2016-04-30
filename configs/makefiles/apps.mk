.PHONY: *


verify_var_app:
	$(if $(APP),,$(error [Error] APP not set!))


define SET_EXTRA_APP
	$(eval APP=$(1))
	$(if $(APP),$(info [Info] Use app name: $(APP)),$(error [Error] APP not set!))
	$(eval EXTRA_APP=-e "app_name=$(APP)")
	$(info [Info] Use app name extra: $(EXTRA_APP))
	$(info [Info])
	@true
endef


jenkins: 
	$(call SET_EXTRA_APP,$@)
