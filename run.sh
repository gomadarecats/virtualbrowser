#!/bin/bash
port='80'
image='tag/iamge'
docker run --rm -d -p $port:6080 -e "REQ=$1" $image
