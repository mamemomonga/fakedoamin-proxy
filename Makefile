IMAGE=fakedomain-proxy

build:
	docker build -t $(IMAGE) .

run:
	docker run --rm \
		-v $(CURDIR)/config.yaml:/config.yaml:ro \
		-v $(CURDIR)/var/certs:/opt/certs \
		-p 8888:8888 \
		$(IMAGE)

shell:
	mkdir -p $(CURDIR)/var/certs
	docker run --rm -it \
		-v $(CURDIR)/config.yaml:/config.yaml:ro \
		-v $(CURDIR)/var/certs:/opt/certs \
		-p 8888:8888 \
		$(IMAGE) sh

