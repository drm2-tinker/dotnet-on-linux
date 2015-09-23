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
apt-get install -qq git > /dev/null


printf "#### Installing MySQL..."
# install MySQL
apt-get install -qq mysql-server > /dev/null

# update root password
mysqladmin -u root password ${db_pass}

# create dev database
mysql -uroot -p${db_pass} -e "create database ${db_name};"


printf "#### Installing Mono..."
# add GPG signing key
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

# add Mono repository
echo "deb http://download.mono-project.com/repo/debian wheezy main" | tee /etc/apt/sources.list.d/mono-xamarin.list

# update the system
apt-get update -qq > /dev/null

# install complete Mono Packages and Mono Server
apt-get install -qq mono-complete mono-fastcgi-server4 > /dev/null


printf "#### Installing Nginx..."
# install nginx
apt-get install -qq nginx > /dev/null

# configure nginx
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup

tee /etc/nginx/sites-available/default << 'EOF'
server {
        listen 80 default_server;
        listen [::]:80 default_server;

        server_name _;
        access_log  /vagrant/dev.access.log;

        location / {
            root  /vagrant/www;
            index index.html index.htm default.aspx Default.aspx;

            fastcgi_index Default.aspx;
            fastcgi_pass  127.0.0.1:9000;

            include /etc/nginx/fastcgi_params;

            fastcgi_param PATH_INFO       "";
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }

        sendfile off;
}
EOF

# make nginx run as vagrant user
sed -i "s/user www-data;/user vagrant;/g" /etc/nginx/nginx.conf

# add vagrant user to nginx group
usermod -a -G www-data vagrant

# start the Mono server as the vagrant user in a detached screen session
sudo -u vagrant /bin/bash -c 'screen -S mono-server -d -m bash -c "fastcgi-mono-server4 --applications=/:/vagrant/www --socket=tcp:127.0.0.1:9000 --logfile=/vagrant/server.log --printlog=true"'

# start nginx
service nginx restart
