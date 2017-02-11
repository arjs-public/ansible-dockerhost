.PHONY: *


define ENV_COMMON
	$(eval ENV=$(1))
	$(if $(ENV),$(info [Info] Use environment: $(ENV)),$(error [Error] ENV not set!))
	$(eval EXTRA_ENV=-e "env_name=$(ENV)")
	$(info [Info] Use environment extra: $(EXTRA_ENV))
	$(info [Info])
	@true
endef


verify_var_env:
	$(if $(ENV),,$(error [Error] ENV not set!))

try:
	$(call ENV_COMMON,$@)

develop:
	$(call ENV_COMMON,$@)

#$(eval ARTIFACT_SPEC=libs-release-local/sites)
#v2.arjs.net.0.1.6.tgz
