.PHONY: *


define ENV_INFO
	$(info [Info] Use environment name: $(ENV))
	$(info [Info] Use environment name extra: $(EXTRA_ENV))
	$(info [Info])
	@true
endef

define SET_ENV_NAME
	$(eval ENV=$(1))
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
