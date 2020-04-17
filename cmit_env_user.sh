#!/bin/bash
# 0.1 2014 Nov - created
# 1.0 2016 Dec - add www
#
# copyright by BROWARSKI
#

# set -x

# only from root
GET_VER=$HOME/get-4.0

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
	cp $HOME/install/filec.cfg $HOME/get/netbone/cfg
        cp $HOME/install/server.lst $HOME/get/netbone/cfg

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
	for DI in backup backup/old cfg idscron log log_perm pid scripts scripts_admin sms zip; do
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
