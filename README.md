# Prerequisite

* Docker (18.06.0+, tested with 18.09.1)
* Docker Compose (tested with 1.23.2)

# How to use it

* Run `make setup` to setup environment
    - Domain to be used for Cozy creation
    - Creation of system CouchDB databases
    - Setup of the Cozy admin passphrase

* Start the world with `make start` or `docker-compose up`

* Create a Cozy with `make cozy`
    - To avoid to be asked for your admin passphrase, you can define the `COZY_ADMIN_PASSWORD` environment variable
