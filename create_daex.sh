#!/bin/bash

# Install requests for pyport
pip3 install -i https://test.pypi.org/simple/ pyport

# Set up swarm
docker swarm init --advertise-addr 127.0.0.1
./network2.sh
#./label_node.sh
./label_node_ds_laptop.sh

# Set up build tools

# Create and deploy portainer
cd stacks/portainer
make build
make deploy
cd ../
init_admin password localhost

# set env vars for portainer login (needed by pyport api calls)
export PORT_USER=admin
export PORT_PASS=password

# Create and deploy registry
pull_image registry:2 localhost
deploy_stack registry registry/docker-compose.yml localhost

# Create and deploy Gitlab
cd gitlab
docker build -t docker.service:5000/daex-meta/gitlab . # is this meant to be build_image? 
cd ../
deploy_stack gitlab gitlab/docker-compose.yml localhost


# Set up Jenkins
cd jenkins
docker build -t docker.service:5000/daex-meta/jenkins .
cd ../

printf "j_user" | docker secret create jenkins_user -
printf "j_pass" | docker secret create jenkins_pass -

deploy_stack jenkins jenkins/docker-compose.yml localhost


# create & build freeipa
cd freeipa
docker build -t docker.service:5000/daex-meta/freeipa-server .
cd ../
deploy_stack freeipa freeipa/docker-compose.yml localhost

# Create and deploy Nginx
build_image docker.service:5000/daex-meta/nginx nginx/ localhost
deploy_stack nginx nginx/docker-compose.yml localhost
add_folder nginx_nginx /etc/nginx nginx/nginx/ localhost
add_folder nginx_nginx /usr/share/nginx/html nginx/html/ localhost
redeploy_stack nginx nginx/docker-compose.yml localhost



# create & build daex-ldap
