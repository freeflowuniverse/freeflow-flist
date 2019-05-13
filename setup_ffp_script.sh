set -x 
if [ -f /var/www/html/humhub/protected/humhub/config/common.php ]; then
        echo humhub version fie exist, checking running version ...
	if [ -z "$HUMHUB_INSTALLATION_VERSION" ];then
		echo HUMHUB_INSTALLATION_VERSION was not set,Pease set it in creating FFP container
		exit 1
	fi
        HUMHUB_CURRENT_PRODUCTION_VERSION=$(grep version /var/www/html/humhub/protected/humhub/config/common.php|awk '{print $3}'| tr -d ,| tr -d \')
        if [ $HUMHUB_CURRENT_PRODUCTION_VERSION != $HUMHUB_INSTALLATION_VERSION ];then
		mkdir -p /backup/humhub`date +%Y-%m-%d`
		ls  /var/www/html/humhub
		du -sh  /var/www/html/humhub/*
		cd /var/www/html/humhub
		cp -rp $(ls -A) /backup/humhub`date +%Y-%m-%d`
		cd /var/www/html
		wget https://www.humhub.org/en/download/package/humhub-$HUMHUB_INSTALLATION_VERSION.tar.gz > /dev/null
		tar -xvf humhub-$HUMHUB_INSTALLATION_VERSION.tar.gz --strip-components=1 --directory /var/www/html/humhub > /dev/null
		iyo_file="/var/www/html/humhub/protected/humhub/modules/user/authclient/IYO.php"
		[ -f "$iyo_file" ] || wget https://raw.githubusercontent.com/freeflowpages/freeflow-iyo-module/master/IYO.php -O $iyo_file
		cp -rp /backup/humhub`date +%Y-%m-%d`/uploads/* /var/www/html/humhub/uploads
		cp -rp /backup/humhub`date +%Y-%m-%d`/protected/modules/* /var/www/html/humhub/protected/modules
		cp -rp /backup/humhub`date +%Y-%m-%d`/themes/* /var/www/html/humhub/themes
		cp -rp /backup/humhub`date +%Y-%m-%d`/protected/config/* /var/www/html/humhub/protected/config
		common_file="/var/www/html/humhub/protected/config/common.php"
		dynamic_file="/var/www/html/humhub/protected/config/dynamic.php"
		wget https://raw.githubusercontent.com/freeflowpages/freeflow-flist/master/common.php -O $common_file
		wget https://raw.githubusercontent.com/freeflowpages/freeflow-flist/master/dynamic.php -O $dynamic_file
		# for prity urls
		[ -f /var/www/html/humhub/.htaccess.dist ] && mv /var/www/html/humhub/.htaccess.dist /var/www/html/humhub/.htaccess
		# run migrate script incase humhub version is updated
		/usr/bin/php /var/www/html/humhub/protected/yii migrate/up --includeModuleMigrations=1
		/usr/bin/php /var/www/html/humhub/protected/yii module/update-all
		# add api module 
		if [ ! -d /var/www/html/humhub/protected/modules/rest ];then
			api_key=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
                        cd /var/www/html/humhub/protected/modules
                        git clone https://github.com/freeflowpages/freeflow-rest-api-module.git rest
                        chown -R www-data:www-data /var/www/
                        chmod -R 775 /var/www/
			(sleep 85 ; /usr/bin/php /var/www/html/humhub/protected/yii module/enable rest) &
                        mysql -uroot -p$ROOT_DB_PASS humhub -e "insert into api_user (client, api_key, active) values ('client1', '$api_key', 1)"
		else 
			cd /var/www/html/humhub/protected/modules/rest 
			git pull
                fi
		
		# add freeflow theme
                if [ ! -d /var/www/html/humhub/themes/Freeflow ];then
                        cd /var/www/html/humhub/themes
                        git clone https://github.com/freeflowpages/freeflow-theme.git Freeflow
                        chown -R www-data:www-data /var/www/; chmod -R 775 /var/www/
			(sleep 85; /usr/bin/php /var/www/html/humhub/protected/yii theme/switch Freeflow) &
		else 
			cd /var/www/html/humhub/themes/Freeflow
			git pull
                fi
		# add 3bot login
		if [ ! -d /var/www/html/humhub/protected/modules/threebot_login ];then
			cd /var/www/html/humhub/protected/modules/
			git clone https://github.com/freeflowpages/freeflow-threebot-login.git threebot_login
			chown -R www-data:www-data /var/www/
			for ((i=1;i<=11;i++));
			    do
			        sleep 1
			        /usr/bin/php /var/www/html/humhub/protected/yii module/list
			        /usr/bin/php /var/www/html/humhub/protected/yii module/enable threebot_login
			    done
			    (sleep 85 ;/usr/bin/php /var/www/html/humhub/protected/yii module/list; /usr/bin/php /var/www/html/humhub/protected/yii module/enable threebot_login) &
		chown -R www-data:www-data /var/www/; chmod -R 775 /var/www/
		fi

        else
                echo humhub is already updated and it is version is $HUMHUB_CURRENT_PRODUCTION_VERSION
		echo "update existing modules ........."
		# re-download common file if there is a modification
		common_file="/var/www/html/humhub/protected/config/common.php"
		wget https://raw.githubusercontent.com/freeflowpages/freeflow-flist/master/common.php -O $common_file
		# add rest module
		if [ -d /var/www/html/humhub/protected/modules/rest ];then
			cd /var/www/html/humhub/protected/modules/rest
			git pull
		else
                        api_key=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
                        cd /var/www/html/humhub/protected/modules
                        git clone https://github.com/freeflowpages/freeflow-rest-api-module.git rest
                        chown -R www-data:www-data /var/www/
                        chmod -R 775 /var/www/
			(sleep 85 ; /usr/bin/php /var/www/html/humhub/protected/yii module/enable rest) &
                        mysql -uroot -p$ROOT_DB_PASS humhub -e "insert into api_user (client, api_key, active) values ('client1', '$api_key', 1)"
		fi
		# add them freeflow 
		if [ -d /var/www/html/humhub/themes/Freeflow ];then
			cd /var/www/html/humhub/themes/Freeflow
			git pull
		else
                        cd /var/www/html/humhub/themes
                        git clone https://github.com/freeflowpages/freeflow-theme.git Freeflow
                        chown -R www-data:www-data /var/www/; chmod -R 775 /var/www/
			(sleep 85 ; /usr/bin/php /var/www/html/humhub/protected/yii theme/switch Freeflow) &
		fi
                # add 3bot login
                if [ ! -d /var/www/html/humhub/protected/modules/threebot_login ];then
                        cd /var/www/html/humhub/protected/modules/
                        git clone https://github.com/freeflowpages/freeflow-threebot-login.git threebot_login
                        chown -R www-data:www-data /var/www/
			            for ((i=1;i<=11;i++));
			            do
			                sleep 1
			                /usr/bin/php /var/www/html/humhub/protected/yii module/list
			                /usr/bin/php /var/www/html/humhub/protected/yii module/enable threebot_login
			            done
			            (sleep 85 ;/usr/bin/php /var/www/html/humhub/protected/yii module/list; /usr/bin/php /var/www/html/humhub/protected/yii module/enable threebot_login) &
		else 
			cd /var/www/html/humhub/protected/modules/threebot_login
			git pull
                fi


        fi
else
	echo humhub version file does not exist, checking if it is fresh install ....
	if [ "$(find /var/www/html/humhub -maxdepth 0 -empty)" ]; then
		cd /var/www/html
		wget https://www.humhub.org/en/download/package/humhub-$HUMHUB_INSTALLATION_VERSION.tar.gz > /dev/null
		tar -xvf humhub-$HUMHUB_INSTALLATION_VERSION.tar.gz --strip-components=1 --directory /var/www/html/humhub > /dev/null
		iyo_file="/var/www/html/humhub/protected/humhub/modules/user/authclient/IYO.php"
		[ -f "$iyo_file" ] || wget https://raw.githubusercontent.com/freeflowpages/freeflow-iyo-module/master/IYO.php -O $iyo_file
		common_file="/var/www/html/humhub/protected/config/common.php"
		dynamic_file="/var/www/html/humhub/protected/config/dynamic.php"
		wget https://raw.githubusercontent.com/freeflowpages/freeflow-flist/master/common.php -O $common_file
		wget https://raw.githubusercontent.com/freeflowpages/freeflow-flist/master/dynamic.php -O $dynamic_file
		[ -f /var/www/html/humhub/.htaccess.dist ] && mv /var/www/html/humhub/.htaccess.dist /var/www/html/humhub/.htaccess
		# run migrate script incase humhub database is old and migrated 
		/usr/bin/php /var/www/html/humhub/protected/yii migrate/up --includeModuleMigrations=1
		/usr/bin/php /var/www/html/humhub/protected/yii module/update-all
		# add rest module if not exist
		if [ ! -d /var/www/html/humhub/protected/modules/rest ];then
			api_key=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
			cd /var/www/html/humhub/protected/modules
			git clone https://github.com/freeflowpages/freeflow-rest-api-module.git rest
			chown -R www-data:www-data /var/www/
			chmod -R 775 /var/www/
			(sleep 85 ; /usr/bin/php /var/www/html/humhub/protected/yii module/enable rest) &
			mysql -uroot -p$ROOT_DB_PASS humhub -e "insert into api_user (client, api_key, active) values ('client1', '$api_key', 1)"
		fi
		# add freeflow theme
		if [ ! -d /var/www/html/humhub/themes/Freeflow ];then
			cd /var/www/html/humhub/themes
			git clone https://github.com/freeflowpages/freeflow-theme.git Freeflow
			chown -R www-data:www-data /var/www/; chmod -R 775 /var/www/
			(sleep 85 ; /usr/bin/php /var/www/html/humhub/protected/yii theme/switch Freeflow) &
		fi
                # add 3bot login
                if [ ! -d /var/www/html/humhub/protected/modules/threebot_login ];then
                        cd /var/www/html/humhub/protected/modules/
                        git clone https://github.com/freeflowpages/freeflow-threebot-login.git threebot_login
                        chown -R www-data:www-data /var/www/
			(sleep 85 ; /usr/bin/php /var/www/html/humhub/protected/yii module/enable threebot_login) &
                else
                        cd /var/www/html/humhub/protected/modules/threebot_login
                        git pull
                fi

	else 
		echo humhub directory is not empty as below 
		ls -A /var/www/html/humhub
	fi

fi
