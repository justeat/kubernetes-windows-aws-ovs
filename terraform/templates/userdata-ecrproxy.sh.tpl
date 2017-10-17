#!/bin/bash
  echo "woo" > /root/woo
  apt update -y
  curl -fsSL https://yum.dockerproject.org/gpg | apt-key add -
  echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > sudo tee /etc/apt/sources.list.d/docker.list
  apt update -y
  echo "install docker"
  apt install -y docker.io dkms
  docker run -d -p 80:80 -p 443:443 catalinpan/aws-ecr-proxy
