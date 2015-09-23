#!/bin/bash


db_name="dev"
db_user="root"
db_pass="dev"


printf "#### Provisioning Vagrant Box..."

printf "#### Updating Vagrant Box..."
# make sure the box is fully up to date
apt-get update -qq > /dev/null

# uncomment the line below to allow the system to upgrade
# apt-get upgrade -y && apt-get dist-upgrade -y

# suppress prompts
export DEBIAN_FRONTEND=noninteractive


printf "#### Installing Necessary Packages..."
# install required packages
apt-get install -qq git


printf "#### Installing MySQL..."
# install MySQL
apt-get install -qq mysql-server

# update root password
mysqladmin -u root password ${db_pass}

# create dev database
mysql -uroot -p${db_pass} -e "create database ${db_name};"
