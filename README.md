# ssrv3-one-click-script
ssrv3-one-click-script


yum install screen wget -y &&screen -S ss 
wget -N --no-check-certificate https://raw.githubusercontent.com/echo-marisn/ssrv3-one-click-script/master/ssrv3.sh && chmod +x ssrv3.h && ./ssrv3.sh 2>&1 | tee ssrv3.log
