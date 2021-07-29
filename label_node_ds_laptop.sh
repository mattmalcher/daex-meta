#!/bin/bash
docker node update --label-add gitlab=true London-GS43VR-6RE
#docker node update --label-add redis=true faraday
#docker node update --label-add mongo=true faraday
docker node update --label-add redis=true London-GS43VR-6RE
docker node update --label-add mongo=true London-GS43VR-6RE
docker node update --label-add nginx=true London-GS43VR-6RE
docker node update --label-add daex=true London-GS43VR-6RE
docker node update --label-add registry=true London-GS43VR-6RE
#docker node update --label-add jenkins=true dirac
docker node update --label-add jenkins=true London-GS43VR-6RE
docker node update --label-add freeipa=true London-GS43VR-6RE

