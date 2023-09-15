BUSER:=root
DBPASSWORD:=p@ssw0rd
DBPORT:=5432
DBNAME:=reasechrep
# https://docs.docker.com/docker-for-mac/networking/#use-cases-and-workarounds
DOCKER_DNS:=db
export DATABASE_DATASOURCE:=postgres://$(DBUSER):$(DBPASSWORD)@$(DOCKER_DNS):$(DBPORT)/$(DBNAME)?sslmode=disable
#export GOOGLE_APPLICATION_CREDENTIALS=./.config/service_account.json
FLYWAY_CONF?=-url=jdbc:postgresql://$(DOCKER_DNS):$(DBPORT)/$(DBNAME) -user=$(DBUSER) -password=$(DBPASSWORD)
SERVICE:=
COMMAND:=

-include ui/.env.local
export $(shell sed 's/=.*//' ui/.env.local)

.PHONY: init
init:
	$(MAKE) -C ui .env.local

firebase.env:
	cp .firebase.env.example firebase.env

.PHONY: docker-compose/command
docker-compose/command:
	docker compose $(COMMAND)

.PHONY: docker-compose/build
docker-compose/build:
	docker compose build

.PHONY: docker-compose/up
docker-compose/up:
	docker compose up

.PHONY: docker-compose/up-d
docker-compose/up-d:
	docker compose up -d

.PHONY: docker-compose/up/service
docker-compose/up/service:
	docker compose up $(SERVICE)

.PHONY: docker-compose/bash/service
docker-compose/bash/service:
	docker compose exec $(SERVICE) /bin/bash

.PHONY: docker-compose/down
docker-compose/down:
	docker compose down

.PHONY: docker-compose/logs
docker-compose/logs:
	docker compose logs -f

.PHONY: docker-compose/down-remove
__docker-compose/down-remove:
	docker compose down --rmi all --volumes --remove-orphans

MIGRATION_SERVICE:=migration
.PHONY: flyway/info
flyway/info:
	docker compose run --rm $(MIGRATION_SERVICE) $(FLYWAY_CONF) info

.PHONY: flyway/validate
flyway/validate:
	docker compose run --rm $(MIGRATION_SERVICE) $(FLYWAY_CONF) validate

.PHONY: flyway/migrate
flyway/migrate:
	docker compose run --rm $(MIGRATION_SERVICE) $(FLYWAY_CONF) migrate

.PHONY: flyway/repair
flyway/repair:
	docker compose run --rm $(MIGRATION_SERVICE) $(FLYWAY_CONF) repair

.PHONY: flyway/baseline
flyway/baseline:
	docker compose run --rm $(MIGRATION_SERVICE) $(FLYWAY_CONF) baseline

DB_SERVICE:=db
.PHONY: postgresql/client
postgresql/client:
	docker compose exec $(DB_SERVICE) psql -U $(DBUSER) -d $(DBNAME)

.PHONY: postgresql/init
postgresql/init:
	docker compose exec $(DB_SERVICE) psql --username=$(DBUSER) --command="create database $(DBNAME)"

.PHONY: __postgresql/drop
__postgresql/drop:
	docker compose exec $(DB_SERVICE) psql --username=$(DBUSER) --command="drop database $(DBNAME)"