COUCHDB_DEFAULT_DATA_PATH=./couchdb/data
COZY_DEFAULT_DATA_PATH=./cozy/data

.SUFFIXES:
MAKEFLAGS += --no-builtin-rules
.DEFAULT_GOAL := setup

.PHONY: set-domain
set-domain:
	@read -r -p "Domain to be used for Cozies creation: " DOMAIN; \
	sed "s/^DOMAIN=.*/DOMAIN=$$DOMAIN/" .example.env > .env

.PHONY: set-email
set-email:
	@read -r -p "Email to be used for Let's Encrypt ACME: " EMAIL; \
	sed "s/^email = .*/email = \"$$EMAIL\"/" traefik/traefik.example.toml > traefik/traefik.toml

.PHONY: set-volumes
set-volumes:
	@read -r -p "Path of the CouchDB data (default to ${COUCHDB_DEFAULT_DATA_PATH}): " COUCHDB_DATA_PATH; \
	if [ -z "$$COUCHDB_DATA_PATH" ]; then \
		COUCHDB_DATA_PATH=${COUCHDB_DEFAULT_DATA_PATH}; \
	fi; \
	sed -i "s#^COUCHDB_VOLUME_PATH=.*#COUCHDB_VOLUME_PATH=$$COUCHDB_DATA_PATH#" .env; \
	mkdir -p "$$COUCHDB_DATA_PATH"

	@read -r -p "Path of the Cozy data (default to ${COZY_DEFAULT_DATA_PATH}): " COZY_DATA_PATH; \
	if [ -z "$$COZY_DATA_PATH" ]; then \
		COZY_DATA_PATH=${COZY_DEFAULT_DATA_PATH}; \
	fi; \
	sed -i "s#^COZY_DATA_PATH=.*#COZY_DATA_PATH=$$COZY_DATA_PATH#" .env; \
	mkdir -p "$$COZY_DATA_PATH"

.PHONY: start-couchdb
start-couchdb:
	docker-compose up -d couchdb
	sleep 5

.PHONY: init-couchdb
init-couchdb: start-couchdb
	for db in _global_changes _metadata _replicator _users ; do \
		docker-compose exec couchdb curl -X PUT http://localhost:5984/$$db; \
	done

.PHONY: cozy-passphrase
cozy-passphrase:
	@echo "Please enter your Cozy admin passphrase when asked"
	@rm -f cozy/cozy-admin-passphrase
	@touch cozy/cozy-admin-passphrase
	@docker-compose run --no-deps --rm cozy cozy-stack config passwd /etc/cozy/cozy-admin-passphrase

traefik/acme.json:
	@touch $@

.PHONY: setup
setup: set-domain set-email set-volumes init-couchdb cozy-passphrase traefik/acme.json

.PHONY: start
start:
	docker-compose up

.PHONY: cozy
cozy:
	@[ -n "$$COZY_ADMIN_PASSWORD" ] || read -r -p "Cozy admin password: " COZY_ADMIN_PASSWORD; \
	read -r -p "Cozy FQDN: " COZY_FQDN; \
	read -r -p "Cozy user password: " COZY_PASSWORD; \
	echo "Creating Cozy $$COZY_FQDN..."; \
	docker-compose exec -e "COZY_ADMIN_PASSWORD=$$COZY_ADMIN_PASSWORD" cozy cozy-stack instance add --passphrase "$$COZY_PASSWORD" --apps home,settings,drive,photos "$$COZY_FQDN"; \
	echo "Your Cozy is available at https://$$COZY_FQDN/!"
