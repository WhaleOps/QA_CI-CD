#!/bin/bash

########################
# 说明：软连接 current 到 current_package下最新版本
########################
ln_current_package(){
# 软连接 删除
cd $work_father_path/current
echo "软连接删除：rm -rf $packge"
rm -rf $packge

# 软连接 增加
cd $work_father_path
echo "软连接增加：ln -s $current_package_path/$packge current"
ln -s $current_package_path/$packge current
}

########################
# 说明：软链接 current 到 current_package下最新版本
########################
get_current_path(){
    install_time=$1
    cd $work_father_path/current_package
    if [ $install_time == "first_install" ]
    then
        current_day=`date +%m%d%H`
        echo "首次安装，需要创建current目录"
        echo "当前current目录是：" $work_father_path/current_package/$version"_"$current_day
        # 如果是 first_install 则创建新目录，非 first_install 则获取最新目录
        current_path=$work_father_path/current/$packge
        current_package_path=$work_father_path/current_package/$version"_"$current_day
        mkdir -p $current_path
        mkdir -p $current_package_path

        # 软连接 current 到 current_package下最新版本
        ln_current_package
    else
        # 获取最新安装包后面的日期，例：file_name是 v2.3.6_122622，获取到 122622
        file_name=`ls -Art |grep $version | tail -n 1`
        current_day=${file_name:0-6}
        echo "当前current目录是：" $work_father_path/current_package/$version"_"$current_day
        current_path=$work_father_path/current/$packge
        current_package_path=$work_father_path/current_package/$version"_"$current_day
    fi



}




########################
# 说明：读取环境信息
########################
read_file_param(){
tool_env_conf_path=/data/whalestudio/tool/env_conf

# 定义读取环境
env_file=$tool_env_conf_path/env_file

# 定义读取环境
env_work_path=$tool_env_conf_path/env_common_path

while read line;do
    eval "$line"
done < $env_file

while read line;do
    eval "$line"
done < $env_work_path


}


########################
# 说明：创建文件夹
########################
create_folder(){

# 定义程序目录、工具目录
package_path=$work_father_path/package
tool_path=$work_father_path/tool
tool_env_conf_path=$work_father_path/tool/env_conf
jar_path=$work_father_path/jar
third_package_path=$work_father_path/third_package
DB_path=$work_father_path/DB

# 创建目录
mkdir -p $package_path
mkdir -p $tool_path
mkdir -p $tool_env_conf_path
mkdir -p $jar_path
mkdir -p $third_package_path
mkdir -p $DB_path


}

########################
# 说明：定义参数
########################
define_param(){

# first_install 会创建新文件夹，非 first_install则获取 /data/whalestudio/current_package/v2.3.6_122622
install_time=$1

# 定义packge包名
packge_tar=whalescheduler-1.0-SNAPSHOT-bin.tar.gz
packge=whalescheduler-1.0-SNAPSHOT-bin

# 读取环境信息
read_file_param

# 创建 package、tool、third_package、jar_path、DB_path 文件夹
create_folder

# 创建 current 软连接到 current_package
get_current_path $install_time

# 定义日志路径
define_log_path

# 定义运维脚本
deploy_sh="$0"


}

########################
# 说明：进程日志路径
########################
define_log_path(){
# add log
api_log_path=`ps -ef|grep api-server|tail -2 | grep -v grep | awk -F "cp" '{print $2}' | awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-api.log/g'`

master_log_path=`ps -ef|grep master-server|tail -2 | grep -v grep | awk -F "cp" '{print $2}' | awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-master.log/g'`

worker_log_path=`ps -ef|grep worker-server|tail -2 | grep -v grep | awk -F "cp" '{print $2}'| awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-worker.log/g'`

alert_log_path=`ps -ef|grep alert-server|tail -2 | grep -v grep | awk -F "cp" '{print $2}' | awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-alert.log/g'`

}



########################
# 说明：deploy环境变量生效
########################
source_deploy(){
echo "========== source 环境变量 ========== "
sed -i '$a\alias deploy="bash /data/whalestudio/tool/deploy_QA.sh"' /etc/profile
source /etc/profile
}




########################
# 说明：打印启动参数
########################
echo_init_param(){
echo "=========== path路径 ========"
echo "deploy_sh脚本目录："$deploy_sh
echo "current_path 目录："$current_path
echo "current_package_path 目录："$current_package_path
echo "package_path 目录："$package_path
echo "tool_path 目录："$tool_path
echo "tool_env_conf_path 目录："$tool_env_conf_path
echo "jar_path 目录："$jar_path

echo "=========== mysql/zk ========"
echo "mysql_ip地址："$mysql_ip
echo "zk_ip地址："$zk_ip
echo "mysql_user："$mysql_user
echo "mysql_passwd："$mysql_passwd
echo "mysql_database："$mysql_database
echo "mysql_port: "$mysql_port

}


########################
# 说明：多台机器执行运维脚本
# 例：bash ws_sprint_2209.sh allstop
########################
remote_all_exec_command(){

for ip in ${addr_list[@]}
do
	 echo "ssh $ip bash $deploy_sh $commad"
     ssh $ip bash $deploy_sh $commad
done
}




########################
# 说明：整体，拷贝文件
# 例：scp /home/ubuntu/sprint_2209/ws_sprint_2209.sh aws2:/home/ubuntu/sprint_2209/
########################
remote_all_cp_file(){
file=$1
for ip in ${addr_list[@]}
do
    cd $tool_path
    echo scp" "$file" "$ip:$tool_path
    scp $tool_path$file $ip:tool_path
done
}



########################
# 说明：启动分布式服务
# 例：2master+6server
########################
remote_all_start(){

for ip in ${addr_list[@]}
do
	echo "开始停止：" $ip
	echo "ssh $ip bash $deploy_sh allstop"
	ssh $ip bash $deploy_sh allstop
done

remote_single_start

}

########################
# 说明：启动分布式服务
# 例：2master+6server
########################
remote_single_start(){

for ip in ${api_list[@]}
do
ssh $ip "bash $deploy_sh start api-server"
done

for ip in ${worker_list[@]}
do
ssh $ip "bash $deploy_sh start worker-server"
done

for ip in ${master_list[@]}
do
ssh $ip "bash $deploy_sh start master-server"
done

for ip in ${alert_list[@]}
do
ssh $ip "bash $deploy_sh start alert-server"
done

}

########################
# 说明：整体服务器，服务启动时区统一变成+8区
# 例：2master+6server
########################
set_all_GMT8(){

for ip in ${addr_list[@]}
do
        set_single_GMT8 $ip
done
}

########################
# 说明：单机，启动时区统一变成+8区
# 例：2master+6server
########################
set_single_GMT8(){
        ip=$1
        echo ssh $ip \"sed -i \'s/-server/-server -Duser.timezone=GMT+08/g\' $current_path/api-server/bin/start.sh\"
        echo ssh $ip \"sed -i \'s/-server/-server -Duser.timezone=GMT+08/g\' $current_path/master-server/bin/start.sh\"
        echo ssh $ip \"sed -i \'s/-server/-server -Duser.timezone=GMT+08/g\' $current_path/worker-server/bin/start.sh\"
        echo ssh $ip \"sed -i \'s/-server/-server -Duser.timezone=GMT+08/g\' $current_path/alert-server/bin/start.sh\"
        ssh $ip  "sed -i 's/-server/-server -Duser.timezone=GMT+08/g' $current_path/api-server/bin/start.sh"
        ssh $ip  "sed -i 's/-server/-server -Duser.timezone=GMT+08/g' $current_path/master-server/bin/start.sh"
        ssh $ip  "sed -i 's/-server/-server -Duser.timezone=GMT+08/g' $current_path/worker-server/bin/start.sh"
        ssh $ip  "sed -i 's/-server/-server -Duser.timezone=GMT+08/g' $current_path/alert-server/bin/start.sh"
}


########################
# 说明：解压文件，v2.3.6
########################
tar_file(){

pwd
echo "cp $package_path/$packge_tar $current_package_path"
cp $package_path/$packge_tar $current_package_path
echo "拷贝文件结束，开始在current_package_path下解压"
cd $current_package_path
tar -zxf $packge_tar

}

########################
# 说明：查看 submit_id
########################
cat_submit_id(){

current_submit_id=`cat $current_path/version.properties | grep abbrev | awk -F "=" '{print $2}'`

echo "current_submit_id: $current_submit_id"


}



########################
# 说明：数据库配置
########################
init_server(){


if [ $is_modify_start_memory == "true" ]
    then
        # 修改master-server 内存
        echo "QA 环境，需修改环境"
        cd $current_path/master-server/bin/
        sed -i 's/-Xms16g -Xmx16g -Xmn8g/-Xms2g -Xmx2g -Xmn256M/g' start.sh

        cd $current_path/worker-server/bin/
        sed -i 's/-Xms16g -Xmx16g -Xmn8g/-Xms2g -Xmx2g -Xmn256M/g' start.sh

        cd $current_path/api-server/bin/
        sed -i 's/-Xms8g -Xmx8g -Xmn4g/-Xms2g -Xmx2g -Xmn256M/g' start.sh

        cd $current_path/alert-server/bin/
        sed -i 's/-Xms8g -Xmx8g -Xmn4g/-Xms2g -Xmx2g -Xmn256M/g' start.sh
    else
        echo "非QA 环境，不需要修改start.sh 配置"
    fi



# 修改配置
cd $current_path/bin/env/
sed  -i 's/localhost:2181/'$zk_ip$zk_port'/g' whalescheduler_env.sh
sed -i '$a\export DATABASE="mysql"' whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_DRIVER_CLASS_NAME="com.mysql.jdbc.Driver"' whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_URL="jdbc:mysql://'$mysql_ip':'$mysql_port'/'$mysql_database'?useUnicode=true&characterEncoding=UTF-8&allowMultiQueries=true"' whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_USERNAME='$mysql_user whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_PASSWORD='$mysql_passwd whalescheduler_env.sh

}


########################
# 说明：初始化 mysql
########################
init_mysql(){


mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -P$mysql_port -e "create database whalescheduler;"

sql_path1=$current_path/tools/conf/sql/dolphinscheduler_mysql.sql
sql_path2=$current_path/tools/conf/sql/whalescheduler_mysql.sql
sourceCommand1="source $sql_path1"
sourceCommand2="source $sql_path2"
echo "开始source："
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e "$sourceCommand1"
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e "$sourceCommand2"
echo "结束source："

}



########################
# 说明：启动/关闭/服务
########################
hanld_server(){

# 启停服务
cd $current_path
case $1 in
    "stop")
        ./bin/whalescheduler-daemon.sh $1 $2
        ps -ef|grep $1|grep -v grep|awk '{print "kill -9 " $2}' |sh
    ;;

    "start")
        ./bin/whalescheduler-daemon.sh $1 $2
    ;;

    "restart_all")
    stop_all_server
    run_all_server
    ;;
    esac
}

########################
# 说明：关闭全服务
########################
stop_all_server(){

# 停止服务
bash $current_path/bin/whalescheduler-daemon.sh stop api-server
bash $current_path/bin/whalescheduler-daemon.sh stop master-server
bash $current_path/bin/whalescheduler-daemon.sh stop worker-server
bash $current_path/bin/whalescheduler-daemon.sh stop alert-server
ps -ef|grep api-server|grep -v grep|awk '{print "kill -9 " $2}' |sh
ps -ef|grep master-server |grep -v grep|awk '{print "kill -9 " $2}' |sh
ps -ef|grep worker-server |grep -v grep|awk '{print "kill -9 " $2}' |sh
ps -ef|grep alert-server |grep -v grep|awk '{print "kill -9 " $2}' |sh
}

########################
# 说明：查看全服务
########################
cat_server(){

ps -ef|grep api-server
ps -ef|grep master-server
ps -ef|grep worker-server
ps -ef|grep alert-server

}

########################
# 说明：启动全服务
########################
run_all_server(){

# 运行服务
echo "$current_path/bin/whalescheduler-daemon.sh start api-server"
bash $current_path/bin/whalescheduler-daemon.sh start api-server
bash $current_path/bin/whalescheduler-daemon.sh start master-server
bash $current_path/bin/whalescheduler-daemon.sh start worker-server
bash $current_path/bin/whalescheduler-daemon.sh start alert-server

}


########################
# 说明：log查看
########################
cat_log(){


echo "hi, 请输入监控日志: api|master|worker|alert "

if [ $log_server == "api" ]
then
    echo "开始监控api"
    echo $api_log_path
    echo "tail -f "$api_log_path
    tail -f $api_log_path

elif [ $log_server == "master" ]
then
    echo "开始监控master"
    master=$master_log_path
    echo "tail -f "$master
    tail -f $master
elif  [ $log_server == "worker" ]
then
    echo "开始监控worker"
    worker=$worker_log_path
    echo "tail -f "$worker
    tail -f $worker

elif  [ $log_server == "alert" ]
then
    echo "开始监控alert"
    alert=$alert_log_path
    echo "tail -f "$alert
    tail -f $alert
fi
}


########################
# 说明：mysql 连接
########################
con_mysql(){

# 连接数据库
echo "mysql -h"$mysql_ip" -u"$mysql_user" -p"$mysql_passwd" -P"$mysql_port" -D"$mysql_database
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -P$mysql_port -D$mysql_database


}

########################
# 说明：将 备份数据库
# 例：mysql_dump
########################
mysql_dump(){

echo "mysqldump -h$mysql_ip -u$mysql_user -P$mysql_port -p$mysql_passwd $mysql_database > $DB_path/$mysql_database"_"$current_day.sql"
mysqldump -h$mysql_ip -u$mysql_user -P$mysql_port -p$mysql_passwd $mysql_database > $DB_path/$mysql_database"_"$current_day.sql

}

########################
# 说明：三方服务安装,java 安装
########################
third_package_java_install(){

cd $third_package_path/
tar -zxvf jdk1.8.0_151.tar.gz
sed -i '$a\export JAVA_HOME='$third_package_path'/jdk1.8.0_151' /etc/profile
sed -i '$a\export PATH=$PATH:$JAVA_HOME/bin:' /etc/profile
sed -i '$a\export CLASS_PATH=$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' /etc/profile
source /etc/profile

}

########################
# 说明：三方服务安装,zookeeper 安装
########################
third_package_zk_install(){

# 创建目录
mkdir -p $third_package_path/zookeeper/data
mkdir -p $third_package_path/zookeeper/log

# 替换配置
cd $third_package_path
tar -zxvf zookeeper.tar.gz
cd zookeeper/conf
sed -i 's/dataDir=/#dataDir=/g' zoo.cfg
sed -i 's/server.1=localhost/server.1='$zk_ip'/g' zoo.cfg
sed -i '$a\dataDir='$third_package_path'/zookeeper/data' zoo.cfg
sed -i '$a\dataLogDir='$third_package_path'/zookeeper/log' zoo.cfg

# 启动配置，root启动
sudo bash $third_package_path/zookeeper/bin/zkServer.sh start


}


tips(){

echo "
*************
*hi, 请输入需要的服务:
*1、首次部署ws：first_install
*2、安装java：third_java_install
*3、安装zookeeper：third_zk_install
*4、重启全部服务：restart
*5、关闭全部服务：allstop
*6、单独停止某个服务：stop api-server
*7、单独启动某个服务：start api-server
*8、日志：log api
*9、初始化mysql：init_mysql
*10、查看全部服务：cat
*11、链接数据库：mysql
*************
"

}

main_run(){


if [ $p_input == "tips" ]
then
       echo_init_param
elif [ $p_input == "mysql_dump" ]
then
        mysql_dump
elif [ $p_input == "third_java_install" ]
then
        third_package_java_install
elif [ $p_input == "third_zk_install" ]
then
        third_package_zk_install
elif [ $p_input == "source_deploy" ]
then
       source_deploy
elif [ $p_input == "first_install" ]
then
        define_param $p_input
        tar_file
        init_server
elif [ $p_input == "other_first_install" ]
then
        remote_all_exec_command "define_param 'today'"
        remote_all_exec_command "tar_file"
        remote_all_exec_command "init_server"
elif [ $p_input == "all_start" ]
then
        remote_all_start
elif [ $p_input == "init_mysql" ]
then
        init_mysql
elif [ $p_input == "restart" ]
then
        stop_all_server
        run_all_server
elif [ $p_input == "log" ]
then
        cat_log
elif [ $p_input == "cat" ]
then
        cat_server
elif [ $p_input == "mysql" ]
then
        con_mysql
elif [ $p_input == "allstop" ]
then
    stop_all_server
elif [ $p_input == "cat_submit_id" ]
then
    cat_submit_id
elif [ $p_input == "stop" ]
then
    hanld_server stop $log_server
elif [ $p_input == "start" ]
then
    hanld_server start $log_server
elif [ $p_input == "restart_server" ]
then
    hanld_server s  top $log_server
    hanld_server start $log_server
elif [ $p_input == "restart" ]
then
    stop_all_server
    run_all_server
fi

}

p_input=$1
log_server=$2
define_param "recent_day"
main_run
