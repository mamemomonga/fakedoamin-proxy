.PHONY: build up down clean

up: var/certs
	docker-compose up -d
	docker-compose logs -f

down:
	docker-compose down

var/certs:
	mkdir -p $@
	docker-compose run -T --rm fakedomain /opt/self-signed-keys.sh | tar xvC $@

build:
	docker-compose build

clean: down
	rm -rf var

