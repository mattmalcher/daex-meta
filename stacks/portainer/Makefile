build:
	docker pull portainer/portainer-ce
	docker tag portainer/portainer-ce docker.service:5000/portainer/portainer-ce
	docker pull portainer/agent
	docker tag portainer/agent docker.service:5000/portainer/agent

deploy:
	docker stack deploy -c docker-compose.yml portainer

push:
	docker push docker.service:5000/portainer/agent
	docker push docker.service:5000/portainer/portainer-ce

stop:
	docker stack rm portainer-ce

clean:
	docker image rm docker.service:5000/portainer/portainer-ce portainer/portainer-ce
	docker image rm docker.service:5000/portainer/agent portainer/agent


