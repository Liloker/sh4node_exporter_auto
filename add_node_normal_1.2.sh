#!/bin/bash 
#默认运行路径root的home目录

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
    echo 'downloading and executing node_exporter......'
    #wget -c -t0 https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz

    tar -xvzf node_exporter-1.3.1.linux-amd64.tar.gz 
    cd node_exporter-1.3.1.linux-amd64/
    echo -e "\033[33m download and unzip successfully, now testing if the port of 9100 is occupied or not ...... \033[0m"
    for(( i=0;i<${#port_array[@]};i++)) do
        time=$(date "+%Y-%m-%d %H:%M:%S")
        port=${port_array[i]};
        port_status=`netstat -nlt|grep ${port_array[i]}|wc -l`
        if [ $port_status -lt 1 ]
        then    
            echo -e "\033[32m [port available] $time $port\033[0m"
            nohup ./node_exporter --web.listen-address 0.0.0.0:$port &  

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
            if [$port -e 9101]
            then echo -e "\033[31m 9100,9101端口均被占用，安装失败\033[0m"
            fi
        fi
    done;
}

#判断9100与9101端口是否正常工作
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
        echo -e "\033[31m [port is not working] $time $port node未处于工作状态 \033[0m"
    else
        echo -e "\033[32m [port is on working] $time $port node处于工作状态 \033[0m"
        curl -s 127.0.0.1:$port
        lsof -i | grep node
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
    echo -e "\033[32m [installed] /root目录下 已存在 node 文件夹与安装包 在9100端口启动该进程......\033[0m"
    cd node_exporter-1.3.1.linux-amd64/
    nohup ./node_exporter --web.listen-address 0.0.0.0:9100 &
    sleep 5 #等1s进程启动
    temp1=`lsof -i | grep node | wc -l`
    if [ $temp1 -ge 1 ]
    then #如果用9100端口启动成功
        echo -e "\033[32m [installed] node_exporter已于9100成功运行\033[0m"
        lsof -i | grep node
    else #否则尝试用9101端口启动
        nohup ./node_exporter --web.listen-address 0.0.0.0:9101 &
        temp2=`lsof -i | grep node | wc -l`
        if [ $temp2 -ge 1 ]
        then 
            echo -e "\033[32m [installed] node_exporter已于9101成功运行\033[0m"
            lsof -i | grep node
        else
            echo -e "\033[31m 其他未知错误 \033[0m"
        fi
    fi
else #安装目录不存在
    echo -e "\033[31m [installed] 当前目录下不存在 node 文件夹与安装包，下面启动下载与安装程序...... \033[0m"
    install_fun
fi

