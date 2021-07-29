# DAEX

Fork of ren-hoek's daex platform scripts. For learning how it all hangs together

# Requirements

Docker
Docker Swarm
python3: 
    * [pyport](https://github.com/ren-hoek/pyport) - a wrapper around the portainer API

Access to docker.io to pull down images 

Locally running docker container registry

# Components

## Portainer
Tools for managing containers with a web ui

Makefile build & deploy does the following steps:

* pull portainer & agent from dockerhub
* tag them in a private registry 'docker.service' accessible on port 5000
* deploys a docker stack made up of portainer & agent using a compose file


## Registry

## Gitlab

## Jenkins

## Nginx

## daex

## freeipa

## mongodb

## redis

# Scripts

## create_daex.sh

Master script:
* sets up the swarm
* calls `network2` to create overlay network 'docproc2'
* calls `label_node` to create feynman/dirac nodes and add labels to them showing which services they host?
* runs the build & deploy steps of the portainer makefile, setting up portainer & agent

* runs init_admin - which is a python script that calls swarm.create_api_string and swarm.initialize_admin_account. 
        * at this point you can get into portainer at [127.0.0.1:9000](http://127.0.0.1:9000/#/home) with admin/password.
* starts using portainer commands via pyport to deploy a local image registry
* builds gitlab and tags in such a way it is sent to local image registry





## network2.sh

creates an [overlay](https://docs.docker.com/network/overlay/) network:

>  a distributed network among multiple Docker daemon hosts. This network sits on top of (overlays) the host-specific networks, allowing containers connected to it (including swarm service containers) to communicate securely when encryption is enabled. Docker transparently handles routing of each packet to and from the correct Docker daemon host and the correct destination container.


# Problems encountered

## Multiple network adaptors confusing docker swarm init
> (daex_py) (base) de-admin@London-GS43VR-6RE:~/repos/daex-meta$ docker swarm init
Error response from daemon: could not choose an IP address to advertise since this system has multiple addresses on interface wlp62s0 (2a01:4b00:85ed:ab00:7ce1:8cae:9386:ea5b and 2a01:4b00:85ed:ab00:b910:488c:1dbe:fe2a) - specify one with --advertise-addr

so, I ran: `docker swarm init --advertise-addr 127.0.0.1` to advertise on localhost - thinking I only want this to run locally anyway. Will be different in prod.

## Nodes do not exist
running label_node.sh generates a load of errors because the nodes which we are trying to add labels to dont exist yet.


## docker pull registry:2 localhost

localhost is an unexpected argument to docker pull. Is this meant to be using pyport's pull_image? e.g.

`pull_image registry:2 localhost`

...this fails because it tries to access `PORT_USER`. I guess that this is meant to be the portainer username & `PORT_PASS` is meant to be the portainer password?

workaround: `export PORT_USER=admin` & `export PORT_PASS=password`

## building gitlab in wrong directory

missing a `cd ../`

## Steps to install python in jenkins dockerfile dont work

Build fails with the error: `/bin/sh: pip3: not found`

Ran the jenkins image the build file starts from with:
`docker container run -it --rm --user root jenkins/jenkins:lts-alpine bash`

Note - need to specify the lts-alpine tag otherwise it uses something else that doesnt have apk!

Found that it genuinely doesnt have pip3. Checking alpine - which is what this image is based off of and found [the following issue](https://github.com/alpinelinux/docker-alpine/issues/91).

Tested out the `apk add cmd:pip3` within the running container & ensured that this allows the subsequent commands to complete.

Added this to the dockerfile & rebuilt.

## Jenkins Secret needs to be present

Secrets arent created by script - understandably, need to find out what best practice for these is.

... in the meantime, can add:

```
printf "j_user" | docker secret create jenkins_user -
printf "j_pass" | docker secret create jenkins_pass -
```

## Building nginx via 'build_image docker.service:5000/daex-meta/nginx nginx/ localhost' not working

You get stuck in a loop of: 'Call:  <number>  Response:  500  Time:  0'

looking in portainer at the portainer agent logs, you can see more detail on what is generating the 500:

> 2021/07/28 16:07:39 [ERROR] [http,docker,proxy] [target_node: feynman] [request: /build?t=docker.service%3A5000%2Fdaex-meta%2Fnginx&q=true] [message: unable to redirect request to specified node: agent not found in cluster]

then

>2021/07/28 16:07:39 http error: The agent was unable to contact any other agent (err=Unable to find the targeted agent) (code=500)
