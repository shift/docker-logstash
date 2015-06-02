all: build push

build:
	docker build -t ${DOCKER_USER}/logstash:1.5.0 .

push: build
	docker push ${DOCKER_USER}/logstash:1.5.0

test: build
	docker run -i ${DOCKER_USER}/logstash:1.5.0 configtest
