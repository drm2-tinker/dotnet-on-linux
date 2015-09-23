#!/bin/bash


printf "#### Provisioning Vagrant Box..."

printf "#### Updating Vagrant Box..."
# make sure the box is fully up to date
apt-get update -qq > /dev/null

# uncomment the line below to allow the system to upgrade
# apt-get upgrade -y && apt-get dist-upgrade -y

# suppress prompts
export DEBIAN_FRONTEND=noninteractive
