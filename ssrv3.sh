#!/bin/bash
#重新整理代码
#Time:2017年11月7日10:37:54
#Author: marisn
#Blog: blog.67cc.cn
#Github版
#一键SS-panel V3_mod_panel搭建 
function install_ss_panel_mod_v3(){
	yum -y remove httpd
	yum install -y unzip zip git
	wget -c https://raw.githubusercontent.com/shizhenying/ssrv3-one-click-script/master/lnmp1.3.zip && unzip lnmp1.3.zip && cd lnmp1.3 && chmod +x install.sh && ./install.sh lnmp
	cd /home/wwwroot/default/
	rm -rf index.html
	git clone https://github.com/shizhenying/ss-panel-v3-mod.git tmp && mv tmp/.git . && rm -rf tmp && git reset --hard
	cp config/.config.php.example config/.config.php
	chattr -i .user.ini
	mv .user.ini public
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	chattr +i public/.user.ini
	wget -N -P  /usr/local/nginx/conf/ http://home.ustc.edu.cn/~mmmwhy/nginx.conf
	service nginx restart
	mysql -uroot -proot -e"create database sspanel;" 
	mysql -uroot -proot -e"use sspanel;" 
	mysql -uroot -proot sspanel < /home/wwwroot/default/sql/sspanel.sql
	cd /home/wwwroot/default
	php composer.phar install
	php -n xcat initdownload
	echo "
	#!/bin/bash
	lnmp restart
	echo -e 'SSR前端重启成功'
	">>/bin/QD
	chmod 777 /bin/QD
	echo "
	#!/bin/bash
	bash /root/shadowsocks/stop.sh
	bash /root/shadowsocks/run.sh
	echo -e 'SSR后端重启成功'
	">>/bin/HD
	chmod 777 /bin/HD
	yum -y install vixie-cron crontabs
	rm -rf /var/spool/cron/root
	echo 'SHELL=/bin/bash' >> /var/spool/cron/root
	echo 'PATH=/sbin:/bin:/usr/sbin:/usr/bin' >> /var/spool/cron/root
	echo '0 0 * * * php /home/wwwroot/default/xcat dailyjob' >> /var/spool/cron/root
	echo '*/1 * * * * php /home/wwwroot/default/xcat checkjob' >> /var/spool/cron/root
	echo "*/1 * * * * php /home/wwwroot/default/xcat synclogin" >> /var/spool/cron/root
	echo "*/1 * * * * php /home/wwwroot/default/xcat syncvpn" >> /var/spool/cron/root
	echo '*/20 * * * * /usr/sbin/ntpdate pool.ntp.org > /dev/null 2>&1' >> /var/spool/cron/root
	echo '30 22 * * * php /home/wwwroot/default/xcat sendDiaryMail' >> /var/spool/cron/root
	/sbin/service crond restart
	#修复数据库
	mv /home/wwwroot/default/phpmyadmin/ /home/wwwroot/default/public/
	cd /home/wwwroot/default/public/phpmyadmin
	chmod -R 755 *
	wget -N -P  /usr/local/php/etc/ https://raw.githubusercontent.com/shizhenying/ssrv3-one-click-script/master/php.ini
	lnmp restart
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	echo "#############################################################"
	echo "# 前端部分安装完成，登录http://${IPAddress}看看吧~          #"
	echo "#默认账号：marisn@67cc.cn                                   #"
	echo "#默认密码：marisn                                           #"
	echo "#搭建完后请务必在前端后台更改账号密码                       #"
	echo "#完成前端搭建请在网站内新建节点                             #"
	echo "#前端重启命令:QD          后端重启命令:HD                   #"
	echo "#############################################################"
}
# 一键添加SS-panel节点
function install_centos_ssr(){
	yum -y update
	yum -y install git 
	yum -y install python-setuptools && easy_install pip 
	yum -y groupinstall "Development Tools" 
	dd if=/dev/zero of=/var/swap bs=1024 count=1048576
	mkswap /var/swap
	chmod 0644 /var/swap
	swapon /var/swap
	echo '/var/swap   swap   swap   default 0 0' >> /etc/fstab
	wget https://raw.githubusercontent.com/shizhenying/ssrv3-one-click-script/master/libsodium-1.0.13.tar.gz
	tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	./configure && make -j2 && make install
	echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
	ldconfig
	yum -y install python-setuptools
	easy_install supervisor
	cd /root
	git clone -b manyuser https://github.com/glzjin/shadowsocks.git "/root/shadowsocks"
	cd /root/shadowsocks
	yum -y install lsof lrzsz
	yum -y install python-devel
	yum -y install libffi-devel
	yum -y install openssl-devel
	pip install -r requirements.txt
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
}
function install_node(){
	clear
	# 取消文件数量限制
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
	read -p "请输入你的对接域名或IP(请加上http:// 如果是本机请直接回车): " Userdomain
	read -p "请输入muKey(在你的配置文件中 如果是本机请直接回车):" Usermukey
	read -p "请输入你的节点编号(非常重要，必须填，不能回车):  " UserNODE_ID
	install_centos_ssr
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	Userdomain=${Userdomain:-"http://${IPAddress}"}
	sed -i "s#https://zhaoj.in#${Userdomain}#" /root/shadowsocks/userapiconfig.py
	Usermukey=${Usermukey:-"mupass"}
	sed -i "s#glzjin#${Usermukey}#" /root/shadowsocks/userapiconfig.py
	UserNODE_ID=${UserNODE_ID:-"3"}
	sed -i '2d' /root/shadowsocks/userapiconfig.py
	sed -i "2a\NODE_ID = ${UserNODE_ID}" /root/shadowsocks/userapiconfig.py
	# 启用supervisord守护
	echo_supervisord_conf > /etc/supervisord.conf
  sed -i '$a [program:ssr]\ncommand = python /root/shadowsocks/server.py\nuser = root\nautostart = true\nautorestart = true' /etc/supervisord.conf
	supervisord
	#iptables
	iptables -F
	iptables -X  
	iptables -I INPUT -p tcp -m tcp --dport 22:65535 -j ACCEPT
	iptables -I INPUT -p udp -m udp --dport 22:65535 -j ACCEPT
	iptables-save >/etc/sysconfig/iptables
	echo 'iptables-restore /etc/sysconfig/iptables' >> /etc/rc.local
	echo "/usr/bin/supervisord -c /etc/supervisord.conf" >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
	echo "#############################################################"
	echo "#          安装完成，节点即将重启使配置生效                 #"
	echo "#############################################################"
	reboot now
}
function change_password(){
	echo -e "\033[31mNote: you must fill in the database password correctly or you can only modify it manually\033[0m"
	read -p "Please enter the database password (the initial password is root):" Default_password
	Default_password=${Default_password:-"root"}
	read -p "Please enter the database password to be set:" Change_password
	Change_password=${Change_password:-"root"}
	echo -e "\033[31mThe password you set is:${Change_password}\033[0m"
mysql -hlocalhost -uroot -p$Default_password --default-character-set=utf8<<EOF
use mysql;
update user set password=passworD("${Change_password}") where user='root';
flush privileges;
EOF
	echo "Start replacing the database information in the Settings file..."
	sed -i '41d' /home/wwwroot/default/config/.config.php
	sed -i "40a\$System_Config['db_password'] = '"${Change_password}"';" /home/wwwroot/default/config/.config.php
	echo "The database password is complete, please remember."
	echo "Your database password is:${Change_password}"
	echo "Restart the configuration to take effect..."
	init 6

}
function install_BBR(){
     wget --no-check-certificate https://github.com/teddysun/across/raw/master/bbr.sh&&chmod +x bbr.sh&&./bbr.sh
}
function install_RS(){
     wget -N --no-check-certificate https://github.com/91yun/serverspeeder/raw/master/serverspeeder.sh && bash serverspeeder.sh
}
function Uninstall_Aliyun(){
yum -y install redhat-lsb
var=`lsb_release -a | grep Gentoo`
if [ -z "${var}" ]; then 
	var=`cat /etc/issue | grep Gentoo`
fi

if [ -d "/etc/runlevels/default" -a -n "${var}" ]; then
	LINUX_RELEASE="GENTOO"
else
	LINUX_RELEASE="OTHER"
fi

stop_aegis(){
	killall -9 aegis_cli >/dev/null 2>&1
	killall -9 aegis_update >/dev/null 2>&1
	killall -9 aegis_cli >/dev/null 2>&1
	killall -9 AliYunDun >/dev/null 2>&1
	killall -9 AliHids >/dev/null 2>&1
	killall -9 AliYunDunUpdate >/dev/null 2>&1
    printf "%-40s %40s\n" "Stopping aegis" "[  OK  ]"
}

remove_aegis(){
if [ -d /usr/local/aegis ];then
    rm -rf /usr/local/aegis/aegis_client
    rm -rf /usr/local/aegis/aegis_update
	rm -rf /usr/local/aegis/alihids
fi
}

uninstall_service() {
   
   if [ -f "/etc/init.d/aegis" ]; then
		/etc/init.d/aegis stop  >/dev/null 2>&1
		rm -f /etc/init.d/aegis 
   fi

	if [ $LINUX_RELEASE = "GENTOO" ]; then
		rc-update del aegis default 2>/dev/null
		if [ -f "/etc/runlevels/default/aegis" ]; then
			rm -f "/etc/runlevels/default/aegis" >/dev/null 2>&1;
		fi
    elif [ -f /etc/init.d/aegis ]; then
         /etc/init.d/aegis  uninstall
	    for ((var=2; var<=5; var++)) do
			if [ -d "/etc/rc${var}.d/" ];then
				 rm -f "/etc/rc${var}.d/S80aegis"
		    elif [ -d "/etc/rc.d/rc${var}.d" ];then
				rm -f "/etc/rc.d/rc${var}.d/S80aegis"
			fi
		done
    fi

}

stop_aegis
uninstall_service
remove_aegis

printf "%-40s %40s\n" "Uninstalling aegis"  "[  OK  ]"

var=`lsb_release -a | grep Gentoo`
if [ -z "${var}" ]; then 
	var=`cat /etc/issue | grep Gentoo`
fi

if [ -d "/etc/runlevels/default" -a -n "${var}" ]; then
	LINUX_RELEASE="GENTOO"
else
	LINUX_RELEASE="OTHER"
fi

stop_aegis(){
	killall -9 aegis_cli >/dev/null 2>&1
	killall -9 aegis_update >/dev/null 2>&1
	killall -9 aegis_cli >/dev/null 2>&1
    printf "%-40s %40s\n" "Stopping aegis" "[  OK  ]"
}

stop_quartz(){
	killall -9 aegis_quartz >/dev/null 2>&1
        printf "%-40s %40s\n" "Stopping quartz" "[  OK  ]"
}

remove_aegis(){
if [ -d /usr/local/aegis ];then
    rm -rf /usr/local/aegis/aegis_client
    rm -rf /usr/local/aegis/aegis_update
fi
}

remove_quartz(){
if [ -d /usr/local/aegis ];then
	rm -rf /usr/local/aegis/aegis_quartz
fi
}


uninstall_service() {
   
   if [ -f "/etc/init.d/aegis" ]; then
		/etc/init.d/aegis stop  >/dev/null 2>&1
		rm -f /etc/init.d/aegis 
   fi

	if [ $LINUX_RELEASE = "GENTOO" ]; then
		rc-update del aegis default 2>/dev/null
		if [ -f "/etc/runlevels/default/aegis" ]; then
			rm -f "/etc/runlevels/default/aegis" >/dev/null 2>&1;
		fi
    elif [ -f /etc/init.d/aegis ]; then
         /etc/init.d/aegis  uninstall
	    for ((var=2; var<=5; var++)) do
			if [ -d "/etc/rc${var}.d/" ];then
				 rm -f "/etc/rc${var}.d/S80aegis"
		    elif [ -d "/etc/rc.d/rc${var}.d" ];then
				rm -f "/etc/rc.d/rc${var}.d/S80aegis"
			fi
		done
    fi

}
stop_aegis
stop_quartz
uninstall_service
remove_aegis
remove_quartz
printf "%-40s %40s\n" "Uninstalling aegis_quartz"  "[  OK  ]"
pkill aliyun-service
rm -fr /etc/init.d/agentwatch /usr/sbin/aliyun-service
rm -rf /usr/local/aegis*
iptables -I INPUT -s 140.205.201.0/28 -j DROP
iptables -I INPUT -s 140.205.201.16/29 -j DROP
iptables -I INPUT -s 140.205.201.32/28 -j DROP
iptables -I INPUT -s 140.205.225.192/29 -j DROP
iptables -I INPUT -s 140.205.225.200/30 -j DROP
iptables -I INPUT -s 140.205.225.184/29 -j DROP
iptables -I INPUT -s 140.205.225.183/32 -j DROP
iptables -I INPUT -s 140.205.225.206/32 -j DROP
iptables -I INPUT -s 140.205.225.205/32 -j DROP
iptables -I INPUT -s 140.205.225.195/32 -j DROP
iptables -I INPUT -s 140.205.225.204/32 -j DROP
}
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
ulimit -c 0
rm -rf ssr*
clear
echo -e "\033[33m=====================================================================\033[0m"
echo -e "\033[33m                   一键SS-panel V3_mod_panel搭建脚本                 \033[0m"
echo -e "\033[33m                                                                     \033[0m"
echo -e "\033[33m                  本脚本由marisn编写，用于学习与交流！               \033[0m"                                                 
echo -e "\033[33m                                                                     \033[0m"
echo -e "\033[33m=====================================================================\033[0m"
echo
echo -e "脚本已由阿里云/腾讯云等正规vps测试通过";
echo
Realip=`curl -s http://tools.67cc.cn/Realip/ip.php`;
pass='blog.67cc.cn';
echo -e "你的IP地址是: $Realip " #检查IP
echo -e "请输入Marisn'blog地址:[\033[32m $pass \033[0m] "
read inputPass
if [ "$inputPass" != "$pass" ];then
    #网址验证
     echo -e "\033[31m很抱歉,输入错误\033[0m";
     exit 1;
fi;
echo -e "\033[31m#############################################################\033[0m"
echo -e "\033[32m#欢迎使用一键SS-panel V3_mod_panel搭建脚本 and 节点添加     #\033[0m"
echo -e "\033[34m#Blog: http://blog.67cc.cn/                                 #\033[0m"
echo -e "\033[35m#请选择你要搭建的脚本：                                     #\033[0m"
echo -e "\033[36m#1.  一键SS-panel V3_mod_panel搭建                          #\033[0m"
echo -e "\033[37m#2.  一键添加SS-panel节点                                   #\033[0m"
echo -e "\033[37m#3.  一键  BBR加速  搭建                                    #\033[0m"
echo -e "\033[36m#4.  一键锐速破解版搭建                                     #\033[0m"
echo -e "\033[35m#5.  一键更改数据库密码                                     #\033[0m"
echo -e "\033[34m#6.  一键卸载阿里云盾监控&屏蔽云盾IP                        #\033[0m"
echo -e "\033[33m#                              PS:建议先搭建加速再搭建SSR-V3#\033[0m"
echo -e "\033[32m#                                   支持   Centos  7.x  系统#\033[0m"
echo -e "\033[31m#############################################################\033[0m"
echo
read num
if [[ $num == "1" ]]
then
install_ss_panel_mod_v3
fi;
if [[ $num == "2" ]]
then
install_node
fi;
if [[ $num == "3" ]]
then
install_BBR
fi;
if [[ $num == "4" ]]
then
install_RS
fi;
if [[ $num == "5" ]]
then
change_password
fi;
if [[ $num == "6" ]]
then
Uninstall_Aliyun
fi;