.PHONY: *

define ENV_COMMON =
	$(info [Info] Use environment: $(ENV))
	$(eval ENVNAME=-e "env_name=$(ENV)")
	$(info [Info] Use environment extra: $(ENVNAME))
	$(eval EXTRAS += -e "artifact_spec=$(ARTIFACT_SPEC)" -e "artifact_name=$(ARTIFACT_NAME)")
	$(info [Info])
	@true
endef

define try =
	$(eval ENV=try)
	$(eval ARTIFACT_SPEC=libs-snapshot-local/sites)
	$(eval ARTIFACT_NAME=ci/current.tgz)
	$(call ENV_COMMON)
endef

try:
	$(call try)

develop:
	$(eval ENV=develop)
	#$(eval ARTIFACT_SPEC=libs-release-local/sites)
	$(eval ARTIFACT_SPEC=libs-snapshot-local/sites)
	$(eval ARTIFACT_NAME=ci/current.tgz)
	$(call ENV_COMMON)

#v2.arjs.net.0.1.6.tgz
