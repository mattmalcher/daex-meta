# DAEX

Fork of ren-hoek's daex platform scripts. For learning how it all hangs together

# Requirements
The following are prerequisites for getting this all up and running:

* Docker
* Docker Swarm
* python3: 
    * [pyport](https://github.com/ren-hoek/pyport) - a wrapper around the portainer API

* Access to dockerhub to pull down images 
* Locally running docker container registry?

# Components

## Portainer
Tools for managing containers with a web ui

Makefile build & deploy does the following steps:

* pull portainer & agent from dockerhub
* tag them in a private registry 'docker.service' accessible on port 5000
* deploys a docker stack made up of portainer & agent using a compose file


## Registry

Because a swarm consists of multiple Docker Engines, a registry is required to distribute images to all of them. 

The registry service is an instance of [docker registry](https://docs.docker.com/registry/).

When running it is accessible on port 5000.

There is a [registry API](https://docs.docker.com/registry/spec/api/)

For example, to list repositories on a locally running registry: http://localhost:5000/v2/_catalog. (or in our case http://docker.service:5000/v2/_catalog)

The registry has its own volume 'data'

https://docs.docker.com/engine/swarm/stack-deploy/#set-up-a-docker-registry


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

Just running `./label_node.sh` again doesnt work because it doesnt exist... so how do we create nodes?

Well, we have one node - thats the name of the machine which we are running this locally on, in this case: `London-GS43VR-6RE`

Running the build command again still fails. Its still looking for `feynman`. Digging some more we can see this is specified in the `build_image.py` which portpy puts in the bin dir of the local virtualenv.

Changing 'feynman' to the current machine name sorts this.

## Now what?

starting the nginx server, it complains about not finding any freeipa stuff. This makes sense because we dont seem to have started anything. 

Tried running:

```
build_image docker.service:5000/daex-meta/freeipa freeipa/ localhost
deploy_stack freeipa freeipa/docker-compose.yml localhost
```

But this doesnt seem to work. Looking in portainer, the service fails to launch because `No such image: docker.service:5000/daex-meta/freeipa:latest`

Is this the right image? or should it be freeipa-server?
Also, looking at docker image ls -a there seem to be a lot of different versions of freeipa being pulled down - almost certainly not right.

```
freeipa/freeipa-server                    centos-7                8d1d0909415e   32 hours ago    928MB
freeipa/freeipa-server                    centos-7-4.6.8          8d1d0909415e   32 hours ago    928MB
freeipa/freeipa-server                    centos-8                01e0aa98640f   32 hours ago    902MB
freeipa/freeipa-server                    centos-8-4.9.2          01e0aa98640f   32 hours ago    902MB
freeipa/freeipa-server                    centos-8-stream         ab54aadc5f25   32 hours ago    1.07GB
freeipa/freeipa-server                    centos-8-stream-4.9.3   ab54aadc5f25   32 hours ago    1.07GB
```

Entertainingly, this there are also a load of older versions on this laptop where it look like someone has done the same thing?

```
freeipa/freeipa-server                    fedora-25               994a41e6b6b3   23 months ago   817MB
freeipa/freeipa-server                    fedora-28               611ed9eb9d62   23 months ago   941MB
freeipa/freeipa-server                    fedora-26               ff4404a55222   23 months ago   790MB
freeipa/freeipa-server                    fedora-27               26695cc35884   23 months ago   825MB
freeipa/freeipa-server                    fedora-23               ec8475c4d733   3 years ago     780MB
freeipa/freeipa-server                    fedora-24               827ba4260b2e   3 years ago     767MB
```

Looking at the registry api - there appear to be no images in the registry??

Hmm - are there meant to be?

Running `build_image docker.service:5000/daex-meta/freeipa freeipa/ localhost` doesnt seem to result in an image being built, which is odd.


OK - I think the issue is that portainer's docker compose defines docker.service as 192.168.1.64 (i.e. a local address that probably only exists at ren-hoek's location) so portainer doesnt have a registry, so isnt putting things in it. Perhaps this is being hidden by using the API through pyport?

Need to fix this & start again I think!

* Attempt 1 - point docker.service at localhost (i.e. 127.0.0.1) using extra.hosts option in the docker-compose file for the portainer stack?
* Attempt 2 - What about making the hosts file point docker.service -> 127.0.0.1 ?

## freeipa no longer has a latest tag

the dockerfile at `stacks/freeipa` specifies: `FROM freeipa/freeipa-server` which since it leaves off the tag, would default to the `:latest` tag. The freeipa maintainers dont assign this tag, in an effort to make people use explicit versions.

fix: change dockerfile to read: `FROM freeipa/freeipa-server:centos-8`

## freeipa bootlooping

Freeipa doesnt seem to start up correctly and keeps trying to relauch. Nothing in the logs accessible via portainer so not sure what the issue is.

`docker container run -it --rm --user root docker.service:5000/daex-meta/freeipa-server:latest bash` seems to start the container with no issues...

navigating to `stacks/freeipa` and running `docker-compose up` gives the following error:

> ERROR: Version in "./docker-compose.yml" is unsupported. You might be seeing this error because you're using the wrong Compose file version. Either specify a supported version (e.g "2.2" or "3.3") and place your service definitions under the `services` key, or omit the `version` key and place your service definitions at the root of the file to use version 1.

So, is it too old or too new? what version of docker-compose does this laptop have....? `docker-compose --version` gives `1.17.1`, which looking at the docker/compose [changelog](https://github.com/docker/compose/blob/master/CHANGELOG.md#1171-2017-11-08) appears to be from 2017... Feels like this might be an issue!

`apt-cache show docker-compose` shows something that makes it look like its coming from the official ubuntu repos, so I think to get a newer version I need to update ubuntu?

### After update...

Still no dice. 

### Debugging Freeipa
Looking at the github repo for the freeipa dockerfiles there is a section on [Debugging](https://github.com/adelton/freeipa-container#debugging) that might give some hints.

Have added environment debug tags into the compose file and I can now see the following:

> The ipa-server-install command failed. See /var/log/ipaserver-install.log for more information

> 2021-08-11T16:07:57Z DEBUG The ipa-server-install command failed, exception: RuntimeError: IPv6 stack is enabled in the kernel but there is no interface that has ::1 address assigned. Add ::1 address resolution to 'lo' interface. You might need to enable IPv6 on the interface 'lo' in sysctl.conf.
2021-08-11T16:07:57Z ERROR IPv6 stack is enabled in the kernel but there is no interface that has ::1 address assigned. Add ::1 address resolution to 'lo' interface. You might need to enable IPv6 on the interface 'lo' in sysctl.conf.


which is more informative! It also points me at this blog, where it looks like the error is something to do with (not) [disabling ip v6](https://osric.com/chris/accidental-developer/2017/10/ipa-server-upgrade-ipv6-stack-is-enabled-in-the-kernel-but-there-is-no-interface-that-has-1-address-assigned/)

There is already something in the compose file about this:
```
sysctls:
      - net.ipv6.conf.all.disable_ipv6=0  
```

indeed, it is mentioned in the docs for the container: https://hub.docker.com/r/adelton/freeipa-server.

so why is it still happening?!

Using the debug option to not exit, we can drop into a shell on the container using portainer. This allows us to execute commands inside the container.

It appears that the sysctls option in the docker-compose file is not having any effect.

> [root@ipa /]# sysctl -a | grep net.ipv6.conf.all.disable
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.all.disable_policy = 0

sysctls has been supported in docker swarm since v

https://docs.docker.com/compose/compose-file/compose-file-v3/#sysctls

supported sysctls include `net.*` 
https://docs.docker.com/engine/reference/commandline/run/#configure-namespaced-kernel-parameters-sysctls-at-runtime 

but it looks like perhaps portainer has had some issues using them?
https://github.com/portainer/portainer/issues/3551
https://github.com/portainer/portainer/issues/2756

looking at the portainer container page, it appears portainer/portainer has been deprecated in favour of portainer/portainer-ce. Updated the dockerfile & docker compose.

### Updated portainer & started again

Now freeipa sttarts and doesnt crash :)


## now what?

got nginx up and running, and think the next step is to get jenkins to build other services & deploy them via portainer, but not sure how to kick it off

can get to jenkins at 127.0.0.1:8081

there is a makefile that looks useful in daex-ldap but this clones things from gitlab


gitlab is at 127.0.0.1:8082 but doesnt seem to want to let you log in - think this is because its http not https? 

It works if you rewrite each url to http, but really we need to get https working I think.

feel like I should be doing something via the webui. lets take a look at what nginx is hosting.

We copied two folder to it:

* nginx/nginx/ to /etc/nginx 
* nginx/html/ to /usr/share/nginx/html

The nginx/nginx contains the config that proxies the gitlab/freeipa/jenkins boxes but I think these config files need some modification

stacks/nginx/nginx/conf.d/freeipa.conf