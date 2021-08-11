#!/bin/bash

# stops all swarm containers (when running locally as the management node)
docker swarm leave --force

docker system prune

docker volume prune

