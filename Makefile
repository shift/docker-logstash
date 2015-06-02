all: build push

build:
	docker build -t ${USER}/logstash:1.5.0 .

push: build
	docker push ${USER}/logstash:1.5.0

test: build
	docker run -i ${USER}/logstash:1.5.0 configtest
