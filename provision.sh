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

# add init script for Mono Server
tee /etc/init.d/monoserve << 'EOF'
#!/bin/bash


### BEGIN INIT INFO
# Provides:          monoserve.sh
# Required-Start:    $local_fs $syslog $remote_fs
# Required-Stop:     $local_fs $syslog $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start FastCGI Mono Server
### END INIT INFO

mono_server=$(which fastcgi-mono-server4)
mono_server_pid=$(ps auxf | grep fastcgi-mono-server4.exe | grep -v grep | awk '{print $2}')

applications="/:/vagrant/www"

case "$1" in
    start)
        if [ -z "${mono_server_pid}" ]; then
            echo "Starting Mono Server now..."
            ${mono_server} --applications=${applications} --socket=tcp:127.0.0.1:9000 --logfile=/vagrant/server.log &
        else
            echo ${applications}
            echo "Mono Server is already running."
        fi
    ;;
    stop)
        if [ -n "${mono_server_pid}" ]; then
            echo "Stopping Mono Server now..."
            kill ${mono_server_pid}
        else
            echo "Mono Server not running."
        fi
    ;;
    restart)
        if [ -n "${mono_server_pid}" ]; then
            kill ${mono_server_pid}
            echo "Restarting Mono Server now..."
        else
            echo "Mono Server not running. Starting now..."
        fi

        if [ -z "${mono_server_pid}" ]; then
            ${mono_server} --applications=${applications} --socket=tcp:127.0.0.1:9000 --logfile=/vagrant/server.log &
        fi
    ;;
esac

exit 0
EOF

# make script executable
chmod +x /etc/init.d/monoserve

# install the script
update-rc.d monoserve defaults

# restart the Mono Server
/etc/init.d/monoserve restart

# start nginx
service nginx restart
