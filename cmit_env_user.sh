#!/bin/bash
# 0.1 2014 Nov - created
# 1.0 2016 Dec - add www
# 2.0 2020 Apr - add git_get to get all software from GIT repository
#
# copyright by BROWARSKI
#

# set -x

# only from root
GET_VER=$HOME/get-4.0

function get_git
{
	HOST=`uname -n`
	echo "GET required files from GIT"
	# for FILE in netbone agent sms idscron scripts scripts_admin watchdog www; do
	for FILE in idscron scripts_admin scripts; do
		echo ""
		echo "--> $FILE start..."

		cd  $HOME/get/
		git clone https://github.com/MaciejBrowarski/$FILE/
		#
		# correct modification time of files
		#
		cd $HOME/get/$FILE
		git ls-files | xargs -I{} git log -1 --date=format:%Y%m%d%H%M.%S --format='touch -t %ad "{}"' "{}" | $SHELL
		cd $HOME/get/

		echo -n "$FILE Makefile..."
		cd  $HOME/get/$FILE/
		pwd
		if [ -f $HOME/get/$FILE/Makefile ]; then
			echo  "Makefile..."
			make 
			echo "done"
			# else
			# 	echo "No found"
		fi
	done

	for FILE in netbone; do
		echo ""
		echo "--> $FILE start..."

		cd  $HOME/get/
		git clone https://github.com/MaciejBrowarski/$FILE/

		cd  $HOME/get/$FILE
		git ls-files | xargs -I{} git log -1 --date=format:%Y%m%d%H%M.%S --format='touch -t %ad "{}"' "{}" | $SHELL
		cd $HOME/get/

		echo -n "$FILE Makefile..."
		cd  $HOME/get/$FILE/
		pwd
		if [ -f $HOME/get/$FILE/Makefile ]; then
			echo "Make cmcore...";
			make cmcore
			echo "done"
			# else
			# 	echo "No found"
		fi
		pwd

		mkdir bin

		for FILE in filec.cfg server.lst; do
			cat cfg/$FILE.$HOST | sed -e "s|USER_ENV|$USER|g" >> cfg/$FILE
		done

	done

}

function unpack_all
{
	echo "Copy files"
	for FILE in netbone agent sms idscron scripts scripts_admin watchdog www; do
		echo ""
		echo "--> $FILE start..."
		if [ -f $HOME/install/$FILE.tar.gz ]; then
			echo -n "$FILE copy..."
			cp $HOME/install/$FILE.tar.gz $HOME/get/
			echo "done"
			echo -n "$FILE unpack..."
			cd $HOME/get
			tar -zxf $FILE.tar.gz
			echo "done"
			cd  $HOME/get/$FILE
			echo -n "$FILE Makefile..."
			if [ -f $HOME/get/$FILE/Makefile ]; then
				echo -n "compile..."
				make 
				echo "done"
			# else
			# 	echo "No found"
			fi
		else
			echo "Not found in install folder"
		fi
	done

	echo "Copy CFG file from install"
	
	cp $HOME/install/install_netbone.sh $HOME/get/

	cp $HOME/install/idscron.cfg $HOME/get/idscron/cfg/	
	 cp $HOME/install/watch.cfg $HOME/get/watchdog/cfg
	cp $HOME/install/watch-root.cfg $HOME/get/watchdog/cfg
	cp $HOME/install/agent.cfg $HOME/get/agent/cfg/

	echo "Change ownerchip of www folder"
	chown www-data:www-data $HOME/get/www/rrd

	# CHECK: initial - as this should be taken fresh
#	cd get
#	echo "Compiling all"
#	./install_netbone.sh
	cd $HOME
}

function initial
{
	if [ -d $GET_VER ]; then
		echo "$GET_VER exist"
	else 
		mkdir $GET_VER
	fi

	echo "Create symlink..."
	ln -s $GET_VER get
	cd get
	pwd
	for DI in backup backup/old idscron log log_perm netbone pid scripts scripts_admin sms zip www; do
		echo "create $DI"
		mkdir $DI
	done
	cd ..
}

function cron_add
{
	crontab install/cron
}
for i in "$@"
do
	case $i in
	cron)
		cron_add
		shift
	;;
    	init)
		initial
		shift
    	;;
    	unpack)
		unpack_all
    		shift
    	;;
    	get_git)
		get_git
    		shift
    	;;
    	*)
            # unknown option
		echo "$0 init|netbone";
    	;;
	esac
done

# TODO:
# idscron_install
# sms_install
# scripts_install
# scripts_admin_install
# watchdog_install

