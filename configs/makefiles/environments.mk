.PHONY: *


define ENV_INFO
	$(info [Info] Use environment name: $(APP))
	$(info [Info] Use environment name extra: $(EXTRA_APP))
	$(info [Info] Use extra vars: $(EXTRAS))
	$(info [Info])
	@true
endef

define SET_ENV_NAME
	$(if $(ENV),,$(error [Error] ENV not set!))
	$(eval EXTRA_ENV=-e "env_name=$(ENV)")
	@true
endef


verify_var_env:
	$(if $(ENV),,$(error [Error] ENV not set!))

try:
	$(call SET_ENV_NAME,$@)
	$(call ENV_INFO)

develop:
	$(call SET_ENV_NAME,$@)
	$(call ENV_INFO)
