#!/bin/bash
#写入开机自启
add_boot()
{
rc_ubuntu=`cat /etc/os-release | grep -o '[\"].*[\"]'| grep -o 'Ubuntu 1[6|8]'|wc -l`
if [ $rc_ubuntu -eq 2 ] #20版本之后无/etc/rc.local
then
        echo "1"
        echo "/root/node_exporter-1.3.1.linux-amd64/node_exporter">> /etc/rc.d/rc.local
else #添加服务
        echo "2"
#touch node_boot
#chmod 777 node_boot
#echo "nohup ./root/node_exporter-1.3.1.linux-amd64/node_exporter &">node_turnon.sh;
cat>/etc/systemd/system/node_exporter.service<<EOF
[Unit]
Description=node_exporter Monitoring System
Documentation=node_exporter Monitoring System

[Service]
ExecStart=/root/node_exporter-1.3.1.linux-amd64/node_exporter --web.listen-address=:9100 

[Install]
WantedBy=multi-user.target
EOF
sleep 3;
systemctl daemon-reload
systemctl start node_exporter.service
systemctl status node_exporter.service
systemctl enable node_exporter.service
#cp ./node_boot /etc/init.d/                
fi

}
add_boot