#!/bin/bash 
#add_node_normal_1.4 默认运行路径root/
check_and_add_boot() #加入开机自启
{
rc_ubuntu=`cat /etc/os-release | grep -o '[\"].*[\"]'| grep -o 'Ubuntu 1[6|8]'|wc -l`
if [ $rc_ubuntu -eq 2 ] #20版本之后无/etc/rc.local
then
    check1=`cat /etc/rc.d/rc.local|grep node_exporter|wc -l`
    if [ $check1 -gt 0 ]
    then
        echo -e "\033[33m 已存在于启动项 \033[0m"
    else
        echo -e "\033[33m 该服务器未添加node自启动进程,Ubuntu version < 20 \033[0m"
        echo "/root/node_exporter-1.3.1.linux-amd64/node_exporter">> /etc/rc.d/rc.local
    fi
else #添加服务
    check2=`find /etc/systemd/system | grep node_exporter.service |wc -l`
    if [ $check2 -gt 0 ]
    then
        echo -e "\033[33m 已存在于启动项 \033[0m"
    else
        echo -e "\033[33m Ubuntu version ≥ 20 \033[0m"
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
echo -e "\033[33m node_exporter.service has been enabled, now the node_exporter will be started automatically in every reboot \033[0m"
fi
fi
}

#下载并解压
install_fun()
{   
    # if [[ `uname -m` = "x86_64" ]]; 
    # then
    #     ARCH="amd64"
    #     # ARGUS_ARCH="linux64"
    #     echo -e "\033[32m[x86_64]  \033[0m"
    # elif [[ `uname -m` = "aarch64" ]]; 
    #     then
    #         # ARCH="arm"
    #         # ARGUS_ARCH="arm64"
    #         echo -e "\033[32m[arm64]  \033[0m"
    #     else
    #         # ARCH="386"
    #         # ARGUS_ARCH="linux32"
    #         echo -e "\033[32m[386]  \033[0m"
    # fi
    uname -a
    echo -e "\033[33m Downloading and executing node_exporter......\033[0m"
    #wget -c -t0 https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz

    #wget -c -t0 https://github-jiasu.oss-cn-hangzhou.aliyuncs.com/plus/node_exporter-1.3.1.linux-amd64.tar.gz
    #使用个人阿里云：默认对于 Linux 实例，默认在管理员 root 用户的 home 目录下；对于 Windows 实例，默认在 C:\Windows\system32 目录

    #使用公司内网oss，文件单独设置公共读权限，无链接过期时间300s
    wget -c -t0 http://leqi-ai.oss-cn-shanghai-internal.aliyuncs.com/result/node_exporter-1.3.1.linux-amd64.tar.gz 

    tar -xvzf node_exporter-1.3.1.linux-amd64.tar.gz 
    cd node_exporter-1.3.1.linux-amd64/
    echo -e "\033[33m Download and unzip successfully, now testing if the port of 9100 is occupied or not ...... \033[0m"
    for(( i=0;i<${#port_array[@]};i++)) do
        time=$(date "+%Y-%m-%d %H:%M:%S")
        port=${port_array[i]};
        port_status=`netstat -nlt|grep ${port_array[i]}|wc -l`
        if [ $port_status -lt 1 ]
        then    
            echo -e "\033[32m [port available] $time $port\033[0m"
            #nohup ./node_exporter --web.listen-address 0.0.0.0:$port &  
            #后台运行，此时可能开启另一进程
            #sleep 5
            #写入开机启动服务并立即开启服务
            check_and_add_boot;
            #检查是否部署成功并运行
            echo -e "\033[33m testing if the node_exporter process is working or not by checking port $port \033[0m"
            run_status2_1=`curl -s localhost:${port_array[i]}| grep '/metrics' |wc -l `
            run_status2_2=`curl -s 127.0.0.1:${port_array[i]}| grep '/metrics' |wc -l `
            #echo "$run_status"
            if [[ $run_status2_1 -ge 1 && $run_status2_2 -ge 1 ]] # 127.0.0.1走网络协议栈
            then
                echo -e "\033[32m work successful\033[0m"
                break
            else
                echo -e "\033[31m work failing\033[0m"
            fi
        else
            echo -e "\033[31m [port occupied] $time $port changing port to 9101...\033[0m"
            if [$port -e 9101] #如果即使换成9101端口，还是被占用，则报错安装失败
            then echo -e "\033[31m Both 9100 and 9101 are occupied, so I stopped the program \033[0m"
            fi
        fi
    done;
}

#判断9100与9101端口是否正常工作，并且检查是否加入启动项
port_array=(9100 9101)
for(( i=0;i<${#port_array[@]};i++)) 
do
    time=$(date "+%Y-%m-%d %H:%M:%S")
    port=${port_array[i]};
    run_status1_1=`curl -s localhost:${port_array[i]}| grep '/metrics' |wc -l `
    run_status1_2=`curl -s 127.0.0.1:${port_array[i]}| grep '/metrics' |wc -l `
    #port_status=`netstat -nlt|grep ${port_array[i]}|wc -l `
    if [[ $run_status1_1 -lt 1 || $run_status1_2 -lt 1 ]]
    then
        echo -e "\033[31m [port is not working] $time $port node not working \033[0m"
    else
        echo -e "\033[32m [port is on working] $time $port node is on working \033[0m"
        curl -s 127.0.0.1:$port
        lsof -i | grep node
        check_and_add_boot;#检查是否加入启动项，未加入的根据ubuntu版本情况加入对应的启动项
        sleep 5;
        exit 0
    fi
done;


#到这一步说明node进程未处于工作状态
echo -e "\033[33m [Checking whether node is already installed] \033[0m"
cd /root
str="node"
instal_stat=`ls | grep ${str} |wc -l `
if [ $instal_stat -ge 2 ]
then #安装目录存在
    echo -e "\033[32m [installed] The files of node_exporter have been in /root/ directory, now start the node process at port 9100......\033[0m"
    cd node_exporter-1.3.1.linux-amd64/
    nohup ./node_exporter --web.listen-address 0.0.0.0:9100 &
    sleep 5 #等5s进程启动
    temp1=`lsof -i | grep node | wc -l`
    if [ $temp1 -ge 1 ]
    then #如果用9100端口启动成功
        echo -e "\033[32m [running] node_exporter is working on port 9100 successfully \033[0m"
        lsof -i | grep node
    else #否则尝试用9101端口启动
        nohup ./node_exporter --web.listen-address 0.0.0.0:9101 &
        temp2=`lsof -i | grep node | wc -l`
        if [ $temp2 -ge 1 ]
        then 
            echo -e "\033[32m [running] node_exporter is working on port 9101 successfully\033[0m"
            lsof -i | grep node
        else
            echo -e "\033[31m [error] Unknown error occured !!!  \033[0m"
        fi
    fi
else #安装目录不存在
    echo -e "\033[31m [none] Nothing about node_exporter in current directory, now loading program for downloading and setuping...... \033[0m"
    install_fun
fi

