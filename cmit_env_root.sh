#!/bin/bash
#
# 0.1 2014 Nov - created
# 1.0 2014 December - fix for test user
# 1.1 2016 November - add tela3010 user and add pkgs (inline.pm)
# 1.2 2016 December - add www folder as part of user env
# 1.3 2017 January - add prla290 user
#
# Copyright by BROWARSKI
#
# increase bash debug
# set -x

# below is variables which describe env
if [ -z "$1" ]; then
        echo "Please provide user name";
        exit 1;
fi

USER=$1
#
# rest variables depend on USER 
# home dir

case $USER in
	mlea2710)
	COMM="mLeasing_2710"
	USER_ID=2710
	;;
        *)
        echo "not know user name...exit"
        exit 1
esac

DIR=/home/$USER
# netbone version
BASE=`pwd`
HOST=`uname -n`
echo "running on $HOST"
#
# install require pkg
INSPKG=0

# only from root

function user_add
{
	# check is user exist
	# add user
	useradd -m -u $USER_ID -s /bin/bash -c $COMM $USER 
	if [ ! -d $DIR ]; then
		echo "homedir $DIR non-exits, creating one"
		mkdir $DIR
		chown $USER $DIR
	fi
}

function install_pkg 
{
	#
	# for odroid
	for PKG in  apache2 make bsd-mailx gcc automake autoconf zlib1g-dev bind9-host libnet-dns-perl libnet-ssleay-perl libsoap-lite-perl libwww-curl-perl librrd4 librrds-perl rrdtool libio-socket-ssl-perl libnet-snmp-perl libinline-perl libssl-dev; do
	#
	# for PKG in apache2 mailx gcc automake1.9 autoconf postfix zlib1g-dev bind9-host libnet-dns-perl libnet-ssleay-perl libsoap-lite-perl libwww-curl-perl librrd4 librrds-perl rrdtool libio-socket-ssl-perl libnet-snmp-perl libinline-perl; do
		# echo -n "checking $PKG...";
		  dpkg-query -W $PKG
		ret=$?
		# echo "return $ret"
		if [ $ret -ne 0 ]; then
			echo -n "$PKG no installed..."
			if [ $INSPKG -ne 0 ]; then
				echo "try to install $PKG"
				apt-get install -y $PKG
			else 
				 echo "";
			fi
		# else 
		# 	echo "Installed"
		fi
	done
}
function pack_all
{
	cd $DIR/get
	for FOLDER in agent idscron netbone scripts scripts_admin sms watchdog www; do
		echo "Pack $FOLDER"
		tar --exclude=*.rrd -zcf /root/cmit_install/install/$FOLDER.tar.gz $FOLDER
		# gzip -9 /root/cmit_install/install/$FOLDER.tar
	done
}
#
# function check element and print if there are some missing
# this check CMIT installation
#
function check
{
	#
	# FOLDERS
	#
	for FOLDER in agent idscron netbone log log_perm pid scripts scripts_admin sms watchdog www zip; do
		F=$DIR/get/$FOLDER
		echo -n "Check Folder $F "
		if [ -d $F ]; then 
			echo "OK"
		else 
			echo "Non Exist"
		fi
	done
	#
	# crontab jobs
	#
	echo "ROOT CRONTAB"
	/bin/grep watchdog /var/spool/cron/crontabs/root
	echo "$USER CRONTAB"
	/bin/grep watchdog /var/spool/cron/crontabs/$USER
}
case $2 in
	check)
		check
	;;
	pkg)
		echo "install require package"
		INSPKG=1
		install_pkg
	;;
	pkg-check)
		echo "check nessesary pkg"
		INSPKG=0
		install_pkg	
	;;
	install)
		echo "Create $USER"
		user_add
		echo "Copy install file for $USER"
		cp ./cmit_env_user.sh $DIR/cmit_env_user.sh
		mkdir $DIR/install
		mkdir $DIR/install/$HOST
		echo "Copy initial files to $DIR/install/"
		# cp install/install_netbone.sh $DIR/install
		#
		# copy *.tar.gz files
		#
		#	for FILE in agent netbone scripts sms scripts_admin idscron watchdog www; do
		#	echo -n "coping $FILE..."
		#	cp install/$FILE.tar.gz $DIR/install
		#	echo "done"
		# done
		# personalise cfg file
		# watchdog, cron, cron.ids
#		for FILE in cron watch.cfg watch-root.cfg idscron.cfg; do
#			echo -n "correct $FILE cfg entry.."
#			cat $USER/$FILE | sed -e "s|USER_ENV|$USER|g" > $DIR/install/$FILE
#			echo "done"
#		done
#
#	 	# host specific cfg file	
#		for FILE in agent.cfg cron; do
#                        echo -n "correct specific for $USER/$HOST/$FILE cfg entry.."
#                        cat $USER/$HOST/$FILE | sed -e "s|USER_ENV|$USER|g" >> $DIR/install/$FILE
#                        echo "done"
#                done
#
		# specific CFG files 
		# netbone
		for FILE in filec.cfg server.lst; do
                        echo -n "correct specific for $USER/$HOST/$FILE cfg entry.."
                        cat $USER/$HOST/cfg/$FILE | sed -e "s|USER_ENV|$USER|g" >> $DIR/install/$FILE
                        echo "done"
                done

		# run user script as $USER
		chown $USER:$USER $DIR/cmit_env_user.sh
		echo ""
		echo "Now run $USER init"
		/bin/su -l -c "$DIR/cmit_env_user.sh init" $USER
		echo ""
		echo "Now run $USER install"
		/bin/su -l -c "$DIR/cmit_env_user.sh get_git" $USER
		echo ""
#                echo "Now run $USER cron"
#                /bin/su -l -c "$DIR/cmit_env_user.sh cron" $USER
		echo "Create symlink for www"
		ln -s $DIR/get/www /var/www/$USER
#		echo "chown rrd_png folder for www"
#		chown www-data:www-data $DIR/get/www/rrd_png/
		echo "!! TODO !!: add crontab entries for root"
		echo "End reached, Please review above logs"
	;;
	pack)
		pack_all
	;;
	remove)
		userdel -r $USER
	;;
	cmcore)
		mv /home/$USER/get/netbone/source/libcmcore.so.1.0.1 /usr/lib
		ln /usr/lib/libcmcore.so.1.0.1 /usr/lib/libcmcore.so 
		ln /usr/lib/libcmcore.so.1.0.1 /usr/lib/libcmcore.so.1
		ldconfig
	;;
	*)
	echo "$0 pkg/pkg-check/pack/install/remove";
esac

