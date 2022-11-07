#===== Variables ===============================================================

#----- Application -------------------------------------------------------------

APP_NAME := cross-rs-gstreamer

#----- Build -------------------------------------------------------------------

## Image to build, i.e. aarch64-unknown-linux-gnu
IMAGE ?=

#----- Git -------------------------------------------------------------------

VCS_HASH := $(shell git rev-parse --verify HEAD)
VCS_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

#----- Docker ------------------------------------------------------------------

DOCKER_BIN := $(shell command -v docker 2> /dev/null)

## Registry path, usually - company name
DOCKER_REGISTRY_PATH ?= sciolence

## List of extra tags for building, delimiter - single space
DOCKER_EXTRA_TAGS ?=

# Adapt the branch name to the tag naming convention. For a typical custom branch
# name it looks like replacing 'username/T000_branch_name' to 'username.T000-branch-name'.
# If, despite the naming conventions, the resulting branch name begins with
# a minus symbol, add the word 'branch' to the beginning.
DOCKER_BRANCH_TAGS := $(shell printf "$(VCS_BRANCH)" | \
	tr '/' '.' | tr -c '[:alnum:].-' '-' | \
	awk '/^-/ {printf "branch"$$0; next} {printf $$0}')
ifeq ($(VCS_BRANCH),main)
    DOCKER_BRANCH_TAGS := $(DOCKER_BRANCH_TAGS) latest
endif

DOCKER_TAGS := $(DOCKER_BRANCH_TAGS) $(DOCKER_EXTRA_TAGS)

#----- Makefile ----------------------------------------------------------------

COLOR_DEFAULT := \033[0m
COLOR_MENU := \033[1m
COLOR_TARGET := \033[93m
COLOR_ENVVAR := \033[32m
COLOR_COMMENT := \033[90m

#===== Functions ===============================================================

define docker_build
	@$(DOCKER_BIN) image build \
		--no-cache=true \
		$(foreach tag_name,$(DOCKER_TAGS), \
			--tag '$(DOCKER_REGISTRY_PATH)/$(APP_NAME)-$(1):$(tag_name)') \
		-f ./docker/$(1).dockerfile \
		./docker;
endef

define docker_push
	@$(foreach tag_name,$(DOCKER_TAGS), \
		$(DOCKER_BIN) push \
			'$(DOCKER_REGISTRY_PATH)/$(APP_NAME)-$(1):$(tag_name)'; \
	)
endef


#===== Targets =================================================================

.DEFAULT_GOAL := help

.PHONY: help \
    docker-build docker-push

#----- Help --------------------------------------------------------------------

## Show this help
help:
	@echo "$(COLOR_MENU)Targets:$(COLOR_DEFAULT)"
	@awk 'BEGIN { FS = ":.*?" }\
		/^## *--/ { print "" }\
		/^## / { split($$0,a,/## /); comment = a[2] }\
		/^[a-zA-Z-][a-zA-Z_-]*:.*?/ {\
			if (length(comment) == 0) { next };\
			printf "  $(COLOR_TARGET)%-15s$(COLOR_DEFAULT) %s\n", $$1, comment;\
			comment = "" }'\
		$(MAKEFILE_LIST)
	@echo "\n$(COLOR_MENU)Properties allowed for overriding:$(COLOR_DEFAULT)"
	@awk 'BEGIN { FS = " *\\?= *" }\
		/^## / { split($$0,a,/## /); comment = a[2] }\
		/^[a-zA-Z][-_a-zA-Z]+ +\?=.*/ {\
			if (length(comment) == 0) { next };\
			printf "  $(COLOR_ENVVAR)%-23s$(COLOR_DEFAULT) - %s\n", $$1, comment;\
			printf "%28s$(COLOR_COMMENT)'\''%s'\'' by default$(COLOR_DEFAULT)\n", "", $$2;\
			comment = "" }'\
		$(MAKEFILE_LIST)
	@echo "$(COLOR_MENU)Usage example:$(COLOR_DEFAULT)\n\
	  make docker-build"

##---- Docker ------------------------------------------------------------------

## Docker : build the image locally
docker-build:
	$(eval DOCKER_TAGS := $(VCS_HASH) $(DOCKER_TAGS))
	$(call docker_build,$(IMAGE))

## Docker : tag and push image to remote registry
docker-push:
	$(eval DOCKER_TAGS := $(VCS_HASH) $(DOCKER_TAGS))
	$(call docker_push,$(IMAGE))
