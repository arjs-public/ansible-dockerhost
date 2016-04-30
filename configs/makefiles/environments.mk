.PHONY: *


define ENV_COMMON
	$(if $(ENV),$(info [Info] Use environment: $(ENV)),$(error [Error] ENV not set!))
	$(eval EXTRA_ENV=-e "env_name=$(ENV)")
	$(info [Info] Use environment extra: $(EXTRA_ENV))
	$(eval EXTRAS += -e "artifact_spec=$(ARTIFACT_SPEC)" -e "artifact_name=$(ARTIFACT_NAME)")
	$(info [Info])
	@true
endef

define SET_ENV_INFO
	$(eval ENV=$(1))
	$(eval ARTIFACT_SPEC=libs-snapshot-local/$(2))
	$(eval ARTIFACT_NAME=$(3))
	$(call ENV_COMMON)
endef


verify_var_env:
	$(if $(ENV),,$(error [Error] ENV not set!))

try:
	$(call SET_ENV_INFO,$@,sites,ci/current.tgz)

develop:
	$(call SET_ENV_INFO,$@,sites,ci/current.tgz)

#$(eval ARTIFACT_SPEC=libs-release-local/sites)
#v2.arjs.net.0.1.6.tgz
