.PHONY: *

define SITE_INFO
	$(info [Info] Use application name: $(NAME))
	$(info [Info] Use application name extra: $(APNEXTRA))
	$(info [Info] Use application environment: $(CONFIGS))
	$(info [Info])
endef

define SITE_RULE_STD
	@test "$(ENV)" || (echo "[Error] ENV not set!" && exit 1)
	@test -s $(CNFG_D)/envs/$(NAME)/$(ENV).json || (echo "[Error] ENV json not found! ($(CNFG_D)/envs/$(NAME)/$(ENV).json))" && exit 1)
	$(eval CONFIGS=-e "@$(CNFG_D)/envs/$(ENV).json")
	$(call SITE_INFO)
endef

define SITE_RULE
	@test "$(ENV)" || (echo "[Error] ENV not set!" && exit 1)
	@test "$(NAME)" || (echo "[Error] NAME not set!" && exit 1)
	@test -s $(CNFG_D)/envs/$(NAME)/$(ENV).json || (echo "[Error] ENV/NAME json not found! ($(CNFG_D)/envs/$(NAME)/$(ENV).json))" && exit 1)
	$(eval APNEXTRA=-e "app_name=$(NAME)")
	$(eval CONFIGS=-e  "@$(CNFG_D)/envs/$(NAME)/$(ENV).json")
	$(call SITE_INFO)
endef

v2.arjs.net:
	$(eval NAME=$@)
	$(eval ARTIFACT_PATH=$(shell echo $(NAME) | tr '.' '\n' | tac | tr '\n' '/'))
	$(eval ARTIFACT_VERSION="0.1.6")
	$(eval EXTRAS += -e "artifact_path=$(ARTIFACT_PATH)" -e "artifact_version=$(ARTIFACT_VERSION)")
	$(call SITE_RULE)
