#!/bin/bash

echo -e "\n\n"
echo -e "\033[34;7mBuild\e[0m"

sudo apt-get update
sudo apt-get upgrade
sudo apt-get -y install git-core curl zlib1g-dev build-essential boxes rbenv
sudo apt-get -y install libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3
sudo apt-get -y install libxml2-dev libxslt1-dev libcurl4-openssl-dev
sudo apt-get -y install python-software-properties libffi-dev imagemagick gsfonts
sudo apt-get -y install rabbitmq-server 
sudo apt-get -y install redis-server nodejs
sudo apt-get -y install  mysql-server  mysql-client  libmysqlclient-dev
sudo rabbitmq-plugins enable rabbitmq_management
sudo service rabbitmq-server restart
wget http://localhost:15672/cli/rabbitmqadmin
chmod +x rabbitmqadmin
sudo mv rabbitmqadmin /usr/local/sbin


echo -e "\n\n"
echo -e "\033[34;7mRuby Install\e[0m"

git clone git://github.com/sstephenson/rbenv.git .rbenv
git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
source ~/.bash_profile
rbenv install --verbose 2.2.2
rbenv global 2.2.2
echo "gem: --no-document" > ~/.gemrc
gem install bundler  -v '1.17.3'
rbenv rehash

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
sudo apt-get install -y apt-transport-https ca-certificates
sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger xenial main > /etc/apt/sources.list.d/passenger.list'
sudo apt-get update
sudo apt-get install -y nginx-extras passenger
sudo rm /etc/nginx/passenger.conf
touch /etc/nginx/passenger.conf
cat <<EOF > /etc/nginx/passenger.conf
passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
passenger_ruby /home/deploy/.rbenv/shims/ruby;
EOF
sudo sed -i 's+# include /etc/nginx/passenger.conf;+include /etc/nginx/passenger.conf;+g' /etc/nginx/nginx.conf

echo -e "\n\n"
echo -e "\033[34;7mSetup production environment variable\e[0m"

echo "export RAILS_ENV=production" >> ~/.bashrc
source ~/.bashrc
mkdir -p ~/peatio
cd peatio
git clone https://github.com/algobasket/PeatioCryptoExchange.git .
bundle install --without development test --path vendor/bundle
bin/init_config

echo "ENTER YOUR SSH IP OR DOMAIN NAME : " sship
read sship
sudo sed -i "s+URL_HOST: localhost:3000+URL_HOST:${sship}+g" config/application.yml

echo "USE http or https : " protocol
read protocol
sed -i "s+URL_SCHEMA: http+URL_SCHEMA: ${protocol}+g" config/application.yml
echo "Enter MySQL Username: " mysqlusername
read mysqlusername
sed -i "s+username: root+username: ${mysqlusername}@+g" config/database.yml
echo "Enter MySQL Password: " mysqlpassword
read mysqlpassword
sed -i "s+password:+password: ${mysqlpassword}@+g" config/database.yml
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /home/deploy/peatio/config/nginx.conf /etc/nginx/conf.d/peatio.conf
sudo service nginx restart
bundle exec rake db:setup
bundle exec rake assets:precompile
bundle exec rake daemons:start
TRADE_EXECUTOR=4 rake daemons:start
RAILS_ENV=production rake solvency:liability_proof
bundle exec rails server
