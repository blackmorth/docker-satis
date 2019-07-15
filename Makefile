.DEFAULT_GOAL := help

.PHONY: help
help:
	@grep -E '(^[a-zA-Z_-]+:.*?## .*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[36m##/[33m/'

# Variables
DOCKER_COMPOSE = docker-compose

##
## Setup
## -----
.PHONY: build up start stop restart state remove bash satis-build down logs config

up: ## start the project
	@echo "== START =="
	$(DOCKER_COMPOSE) up -d satis

start: up

build: ## Build the project
	@$(DOCKER_COMPOSE) build --pull

rebuild: ## Rebuild the project
	@$(DOCKER_COMPOSE) build --pull --no-cache

stop: ## Stop the project
	@echo "== STOP =="
	@$(DOCKER_COMPOSE) stop

restart: start ## Restart the project

state: ## state the project
	@echo "== STATE =="
	@$(DOCKER_COMPOSE) ps

remove: ## REMOVE the project
	@$(DOCKER_COMPOSE) rm --force

sh: ## sh to the project
	@echo "== SH =="
	@$(DOCKER_COMPOSE) exec satis sh

logs: ## show logs the project
	@$(DOCKER_COMPOSE) logs -ft --tail=1000

down: ## down correctly the project
	@$(DOCKER_COMPOSE) down --volumes --remove-orphans

satis-build: ## build with sh script
	@echo "== SATIS BUILD =="
	@$(DOCKER_COMPOSE) exec satis ./scripts/build.sh

config: .env.dist config/parameters.satisfy.yml.dist config/satis.json.dist ## Copy Config to good place.
	cp .env.dist .env
	cp config/parameters.satisfy.yml.dist config/parameters.satisfy.yml
	cp config/satis.json.dist config/satis.json