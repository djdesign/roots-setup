#!/bin/bash

# set this variable - it will be used as both the root folder name and the theme name for sage
# no spaces - should not be a URL - I'm using 'my-site' or similar
# SITENAME="your-site-name"
# Usage Example: trellis-setup sitename git

SITENAME=$1
GIT=$2

# MUTLI=$3
# --------------[DO NOT EDIT BELOW HERE]---------------------------

# DealBreakers
# phpv=$(php -v); 
# if [[ $phpv < 5.6]];then 

# fi

# -----------[CONDITIONAL CHECKS]--------------------------------------
# checking if sitename is set
if [ -z $SITENAME ]; then
	echo "Missing parameter SITENAME: $1 "
	echo "Correct Usage: trellis-setup SITENAME"
	exit
fi

# checking going to use bitbucket server
if [[ $GIT > 0 ]]; then
	echo 'git true';

	# Get bitbucket userinfo
	. ~/scripts/user.sh

	# Add BitBucket username/password to have a remote repo setup
	if [[ ! -f ~/scripts/user.sh ]]; then
		echo "No User file. Check your files for user.sh"
		exit
	fi
	if [[ -f ~/scripts/user.sh ]]; then

		if [[ -z "$BITBUCKET_USER" ]]; then
			echo "Empty username & password. Why you Empty?";
			exit;
		fi
	fi
fi

# active vagrant?
read -p "Want Sage9 Development? Reply [Yn]" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    SAGE9=1
    SAGE9DEV='--branch=sage-9'
    SAGE_VER=9
else
	SAGE9=0
	SAGE_VER=9
fi

# active vagrant?
read -p "Want Multisite? Reply [Yy]" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    MUTLI=1
else
	MUTLI=0
fi

# save current pwd
cwd=$(pwd)/$SITENAME
# clone bedrock, trellis and sage
mkdir $SITENAME && cd $SITENAME
git clone --depth=1 git@github.com:roots/trellis.git && rm -rf trellis/.git
# git clone --depth=1 git@github.com:Idealien/centrellis.git && rm -rf centrellis/.git && mv centrellis trellis
git clone --depth=1 git@github.com:roots/bedrock.git site && rm -rf site/.git
git clone --depth=1 git@github.com:roots/sage.git site/web/app/themes/$SITENAME && rm -rf site/web/app/themes/$SITENAME/.git
# mv trellis/Vagrantfile .

# # update trellis path
# x="__dir__"
# y="'trellis'"
# # sed -i -e "s/$x/$y/g" ./Vagrantfile
# # rm ./Vagrantfile-e
# sed -i -e "s/$x/$y/g" ./trellis/Vagrantfile
# rm ./trellis/Vagrantfile-e

# update local domain name
sed -i '' 's/example.com/'$SITENAME'.dev/g' $(find $cwd -name "*.yml");
sed -i '' 's/example.dev/'$SITENAME'.dev/g' $(find $cwd -name "*.yml");

# update vagrant ipaddress
sed -i '' 's/192.168.50.5/192.168.50.6/g' $(find $cwd -name "*.yml");

# add default theme
echo "define('WP_DEFAULT_THEME', '$SITENAME');" >> $cwd/site/config/application.php

if [[ $MUTLI > 0 ]]; then
	echo "/* Multisite */
	define('WP_ALLOW_MULTISITE', true);
	define('MULTISITE', true);
	define('SUBDOMAIN_INSTALL', true); // Set to false if using subdirectories
	define('DOMAIN_CURRENT_SITE', env('DOMAIN_CURRENT_SITE'));
	define('PATH_CURRENT_SITE', '/');
	define('SITE_ID_CURRENT_SITE', 1);
	define('BLOG_ID_CURRENT_SITE', 1);"
	>> $cwd/site/config/application.php;
	
fi

# configure theme
cd $cwd/site/web/app/themes/$SITENAME
npm install

# check if sage9 else sage 8
if [[ $SAGE9 > 0 ]]
then
	echo ' '
	echo ' start of sage 9 dev'
	echo ' '
  	sed -i '' 's/example.dev/'$SITENAME'.dev/g' $(find ./assets/ -name "config.json");
	npm run build # used in sage 9
else
	# bower install # used in sage 8
	# bower-update-all
	# gulp
	echo ' '	
	echo ' start of sage 9'
	echo ' '
  	sed -i '' 's/example.dev/'$SITENAME'.dev/g' $(find ./assets/ -name "config.json");
	npm run build # used in sage 9
fi

# add soil
cd $cwd/site && composer require roots/soil

# ansible roles
cd $cwd/trellis && ansible-galaxy install -r requirements.yml

# setup new repo at BitBucket
# curl --user $BITBUCKET_USER:$BITBUCKET_PASS https://api.bitbucket.org/1.0/repositories/ --data name=$SITENAME
cd $cwd
git init
# git remote add origin git@bitbucket.org:$BITBUCKET_USER/$SITENAME.git
git add -A
git commit -m 'initial commit'

# active vagrant?
read -p "Want to activate Vagrant? Reply [Yy] to activate" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    cd $cwd/trellis
    vagrant up
fi

# active IDE?
read -p "Want to activate IDE? Reply [Yy] to activate" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    cd $cwd
	pstorm .
	# open atom
fi

# display some output
echo "Your New Trellis/Bedrock/Sage$SAGE_VER site $SITENAME is installed in $cwd and available at $SITENAME.dev.\n"
echo "There is still setup requirements for trellis linked to staging/production"