#!/bin/bash
      
pull(){
cd /home/wenzixin
cd WhaleScheduler
git fetch origin zhongxin_master
git pull origin zhongxin_master
  
}
      
clone_init(){
cd /home/wenzixin
sudo rm -r WhaleScheduler/
git clone git@github.com:WhaleOps/WhaleScheduler.git
cd WhaleScheduler
git fetch origin zhongxin_master
git checkout -b zhongxin_master origin/zhongxin_master
  
}
      
build(){
cd /home/wenzixin/WhaleScheduler
mvn -B clean install -Prelease -Dmaven.test.skip=true -Dcheckstyle.skip=true -Dmaven.javadoc.skip=true
}
      
tar_file(){
       

cd /opt/release
pwd
echo $today
sudo rm -r $today/
echo "删除结束"

FILE=/opt/release/$packge_tar
if test -f "$FILE"; 
then
    echo "$FILE 存在，开始解压"
    tar -zxf $packge_tar
    mv $packge $today
    echo "结束解压"
else
    echo "文件不存在，exit"
    exit 1
fi   
       
   
  
}
   
       
conf_server(){
       
p_api_lib=/opt/release/$today/api-server/libs/
p_master_lib=/opt/release/$today/master-server/libs/
p_worker_lib=/opt/release/$today/worker-server/libs/
p_alert_lib=/opt/release/$today/alert-server/libs/
p_tools_lib=/opt/release/$today/tools/libs/
p_st_lib=/opt/release/$today/standalone-server/libs/
       
       
p_api_conf=/opt/release/$today/api-server/conf/
p_master_conf=/opt/release/$today/master-server/conf/
p_worker_conf=/opt/release/$today/worker-server/conf/
p_alert_conf=/opt/release/$today/alert-server/conf/
p_tools_conf=/opt/release/$today/tools/conf/
p_st_conf=/opt/release/$today/standalone-server/conf/
       
       
cp $p0 $p4 $p_api_lib
cp $p0 $p4 $p_master_lib
cp $p0 $p4 $p_worker_lib
cp $p0 $p4 $p_alert_lib
cp $p0 $p4 $p_tools_lib
cp $p0 $p4 $p_st_lib
       
echo "cp $p0 $p_api_lib"
       
cp $p1 $p2 $p3 $p_api_conf
cp $p1 $p2 $p3 $p_master_conf
cp $p1 $p2 $p3 $p_worker_conf
cp $p1 $p2 $p3 $p_alert_conf
cp $p1 $p2 $p3 $p_tools_conf
cp $p1 $p2 $p3 $p_st_conf
      
      
      
echo "cp $p1 $p2 $p3 $p_api_conf"
}
       
init_server(){
      
# python、spark 变量替换
sed  -i 's/\/opt\/soft\/python/\/usr\/bin\/python/g' /opt/release/$today/worker-server/conf/dolphinscheduler_env.sh
sed  -i 's/spark2/spark/g' /opt/release/$today/worker-server/conf/whalescheduler_env.sh

# 环境变量替换
cd /opt/release/$today/bin/env/
sed  -i 's/localhost:2181/'$zk_ip':2181/g' whalescheduler_env.sh
sed -i '$a\export DATABASE="mysql"' whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_DRIVER_CLASS_NAME="com.mysql.jdbc.Driver"' whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_URL="jdbc:mysql://'$mysql_ip':3306/300beta?useUnicode=true&characterEncoding=UTF-8&allowMultiQueries=true"' whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_USERNAME="root"' whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_PASSWORD="root@123"' whalescheduler_env.sh
echo "替换jdbc配置成功"
     
cd /opt/release/$today/master-server/bin/
sed -i 's/Xmn2g/Xmn1g/g' start.sh
echo "master内存改小 成功"
      
      
cd /opt/release/$today/worker-server/bin/
sed -i 's/Xmn2g/Xmn1g/g' start.sh
echo "worker内存改小 成功"
     
}
      
define_param(){
      
packge_tar=whalescheduler-1.0-SNAPSHOT-bin.tar.gz
packge=whalescheduler-1.0-SNAPSHOT-bin
p0=/home/wenzixin/tool/mysql-connector-java-8.0.16.jar
p1=/home/wenzixin/tool/common.properties
p2=/home/wenzixin/tool/core-site.xml
p3=/home/wenzixin/tool/hdfs-site.xml
p4=/home/wenzixin/tool/ojdbc8.jar
       
today=`date +%m%d`
echo $today
       
}
      
no_hdfs(){
      
echo "开始删除hdfs配置"
sudo rm /opt/release/$today/api-server/conf/core-site.xml
sudo rm /opt/release/$today/api-server/conf/hdfs-site.xml
sudo rm /opt/release/$today/worker-server/conf/core-site.xml
sudo rm /opt/release/$today/worker-server/conf/hdfs-site.xml
sudo rm /opt/release/$today/master-server/conf/core-site.xml
sudo rm /opt/release/$today/master-server/conf/hdfs-site.xml
sudo rm /opt/release/$today/alert-server/conf/core-site.xml
sudo rm /opt/release/$today/alert-server/conf/hdfs-site.xml
echo "结束删除hdfs配置"
}
      
init_mysql(){
      
init_hdfs
sql_path1="/opt/release/$today/tools/conf/sql/dolphinscheduler_mysql.sql"
sql_path2="/opt/release/$today/tools/conf/sql/whalescheduler_mysql.sql"
sourceCommand1="source $sql_path1"
sourceCommand2="source $sql_path2"
echo "开始source："
echo $sourceCommand1
echo $sourceCommand2
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D "300beta" -e "$sourceCommand1"
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D "300beta" -e "$sourceCommand2"
echo "结束source："
}
       
      
      
hanld_server(){
cd /opt/release/$today
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
      
      
stop_all_server(){
sh /opt/release/$today/bin/whalescheduler-daemon.sh stop api-server
sh /opt/release/$today/bin/whalescheduler-daemon.sh stop master-server
sh /opt/release/$today/bin/whalescheduler-daemon.sh stop worker-server
sh /opt/release/$today/bin/whalescheduler-daemon.sh stop alert-server
ps -ef|grep api-server|grep -v grep|awk '{print "kill -9 " $2}' |sh
ps -ef|grep master-server |grep -v grep|awk '{print "kill -9 " $2}' |sh
ps -ef|grep worker-server |grep -v grep|awk '{print "kill -9 " $2}' |sh
ps -ef|grep alert-server |grep -v grep|awk '{print "kill -9 " $2}' |sh
}
      
cat_server(){
ps -ef|grep api-server
ps -ef|grep master-server
ps -ef|grep worker-server
ps -ef|grep alert-server
      
}
      
run_all_server(){
echo "/opt/release/$today/bin/whalescheduler-daemon.sh start api-server"
sh /opt/release/$today/bin/whalescheduler-daemon.sh start api-server
sh /opt/release/$today/bin/whalescheduler-daemon.sh start master-server
sh /opt/release/$today/bin/whalescheduler-daemon.sh start worker-server
sh /opt/release/$today/bin/whalescheduler-daemon.sh start alert-server
  
echo "检查服务："
cat_server
echo "检查服务："
}
      
      
scp_master(){
sudo su - root <<EOF
scp /root/.jenkins/workspace/zhongxin_master/whalescheduler-dist/target/$packge_tar root@ctyun1:/opt/release/
scp /root/.jenkins/workspace/zhongxin_master/whalescheduler-dist/target/$packge_tar root@ctyun2:/opt/release/
scp /root/.jenkins/workspace/zhongxin_master/whalescheduler-dist/target/$packge_tar root@ctyun4:/opt/release/
scp /root/.jenkins/workspace/zhongxin_master/whalescheduler-dist/target/$packge_tar root@ctyun6:/opt/release/
scp /root/.jenkins/workspace/zhongxin_master/whalescheduler-dist/target/$packge_tar root@ctyun8:/opt/release/
scp /root/.jenkins/workspace/zhongxin_master/whalescheduler-dist/target/$packge_tar root@ctyun5:/opt/release/
EOF
}

scp_830(){
sudo su - root <<EOF
scp /root/.jenkins/workspace/zhongxin_830/whalescheduler-dist/target/$packge_tar root@ctyun1:/opt/release/
scp /root/.jenkins/workspace/zhongxin_830/whalescheduler-dist/target/$packge_tar root@ctyun2:/opt/release/
scp /root/.jenkins/workspace/zhongxin_830/whalescheduler-dist/target/$packge_tar root@ctyun4:/opt/release/
expect -c "
    spawn scp -r /root/.jenkins/workspace/zhongxin_830/whalescheduler-dist/target/$packge_tar root@ctyun6:/opt/release/
    expect { 
        \"*password\" {set timeout 500;send \"74eO%+s$\r\";}
    }
expect eof"

echo "ctyun6复制完成"
scp /root/.jenkins/workspace/zhongxin_830/whalescheduler-dist/target/$packge_tar root@ctyun8:/opt/release/
EOF
}

scp_815(){
sudo su - root <<EOF
scp /root/.jenkins/workspace/zhongxin_815/whalescheduler-dist/target/$packge_tar root@ctyun5:/opt/release/
EOF
}
      
check_api_server(){
 
    api=`ps -ef|grep api-server|tail -3 | grep -v grep | awk '{print $18}' | awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-api.log/g'`
    echo "开始监控 api"
    echo "tail -f "$api
    tmp=$(tail -n1 $api)
    echo $tmp > file.txt
    key=`awk '{print $10}' file.txt`
    if [ $key == "success," ]
    then
        echo "api 启动成功"
    else
        echo "api 启动失败"
        cat file.txt
        exit 1
    fi
}

check_worker_server(){
 
    worker=`ps -ef|grep worker-server|tail -3 | grep -v grep | awk '{print $18}' | awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-worker.log/g'`
    echo "开始监控 worker"
    echo "tail -f "$worker
    tmp=$(tail -n1 $worker)
    echo "结束监控 worker"
    echo $tmp > file.txt
    key=`awk '{print $13}' file.txt`
    if [ $key == "success," ]
    then
        echo "worker 启动成功"
    else
        echo "worker 启动失败"
        cat file.txt
        exit 1
    fi
}
 
check_master_server(){
 
    master=`ps -ef|grep master-server|tail -3 | grep -v grep | awk '{print $18}' | awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-master.log/g'`
    echo "开始监控 master"
    echo "tail -f "$master
    tmp=$(tail -n1 $master)
    echo "结束监控 master"
    echo $tmp > file.txt
    key=`awk '{print $12}' file.txt`
    if [ $key == "success," ] || [ $key == "addrList:" ]
    then
        echo "master 启动成功"
    else
        echo "master 启动失败"
        cat file.txt
        exit 1
    fi
}

check_alert_server(){
 
    alert=`ps -ef|grep alert-server|tail -3 | grep -v grep | awk '{print $18}' | awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-alert.log/g'`
    echo "开始监控 alert"
    echo "tail -f "$alert
    tmp=$(tail -n1 $alert)
    echo "结束监控 alert"
    echo $tmp > file.txt
    key=`awk '{print $10}' file.txt`
    if [ $key == "success," ]
     then
        echo "alert 启动成功"
    else
        echo "alert 启动失败"
        cat file.txt
        exit 1
    fi
}

cat_log(){
echo "hi, 请输入监控日志: api|master|worker "
      
if [ $log_server == "api" ]
then
    echo "开始监控api"
    api=`ps -ef|grep api-server|tail -3 | grep -v grep | awk '{print $18}' | awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-api.log/g'`
    echo "tail -f "$api
    tail -f $api
      
elif [ $log_server == "master" ]
then
    echo "开始监控master"
    master=`ps -ef|grep master-server|tail -3 | grep -v grep | awk '{print $18}' | awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-master.log/g'`
    echo "tail -f "$master
    tail -f $master
elif  [ $log_server == "worker" ]
      
then
    echo "开始监控worker"
    worker=`ps -ef|grep worker-server|tail -3 | grep -v grep | awk '{print $18}' | awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-worker.log/g'`
    echo "tail -f "$worker
    tail -f $worker
   
elif  [ $log_server == "alert" ]
then
    echo "开始监控alert"
    alert=`ps -ef|grep alert-server|tail -3 | grep -v grep | awk '{print $18}' | awk -F ":" '{print $1}' | sed 's/conf/logs\/whalescheduler-alert.log/g'`
    echo "tail -f "$alert
    tail -f $alert
fi
}
      
init_hdfs(){
      
echo "开始初始化 hdfs"
sudo rm -r /dolphinscheduler/whalescheduler/resources
sudo rm -r /dolphinscheduler/whalescheduler/udfs
echo "结束初始化 hdfs"
}
      
con_mysql(){
      
      
commond_count="select count(1) from t_ds_command"
process_instance="select count(1) from t_ds_process_instance where state=7"
task_instance="select count(1) from t_ds_task_instance where state=7"
time="select TIMESTAMPDIFF(second,min(start_time),max(end_time)) from t_ds_process_instance where state=7"
      
      
echo "连接"
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D "300beta"
      
      
}
     
mock_base(){
     
cd /home/wenzixin/postman/data
echo "基础服务mock：开始"
newman run 01-基础用例.postman_collection.json --delay-request 10 --working-dir /home/wenzixin/postman/data/jar_floder/ -e test_env.postman_environment.json -r cli,html | tee mock.txt
echo "基础服务mock：结束"

}



mock_user(){

cd /home/wenzixin/postman/data
echo "业务mock：开始"
newman run 02-业务用例.postman_collection.json --delay-request 10 --working-dir /home/wenzixin/postman/data/jar_floder/ -e test_env.postman_environment.json -r cli,html | tee mock.txt
echo "业务mock：结束"
}

mock_assert(){

        res=`cat /home/wenzixin/postman/data/mock.txt | grep AssertionError | head -1`
        assert=AssertionError
        if [[ "$res" == *"$assert"* ]]
        then
        echo "test_case contain Error!!!"
        exit 1
        else
        echo "all test_case running ok"
        fi
}

     
init_zk(){

        mysql_ip="ctyun5"
        zk_ip="ctyun5"
	    mysql_user="root"
	    mysql_passwd="root@123"
        echo "mysql_ip: $mysql_ip"
        echo "zk_ip: $zk_ip"
}

tips(){
 
echo "
*************
*hi, 请输入需要的服务:
*1、编译：build
*2、初始化配置：conf
*3、重启全部：restart
*4、关闭全部：allstop
*5、单独停止：stop
*6、单独启动：start
*7、日志：log api
*8、初始化mysql：init_mysql
*9、查看全部服务：cat
*10、链接数据库：mysql
*11、快速冒烟: mock
*12、拷贝：scp
*************
"
 
}   
 
main_run(){

if [ $p_input == "build" ]
then
        echo "1、编译：build"
        pull
        build
elif [ $p_input == "tips" ]
then     
                tips
elif [ $p_input == "conf" ]
then
        echo "1、初始化配置：conf"
        tar_file
        conf_server
        init_server
elif [ $p_input == "no_hdfs" ]
then
        echo "1、配置：hdfs"
        no_hdfs
elif [ $p_input == "init_mysql" ]
then
        echo "1、初始化：init_mysql"
        init_mysql
elif [ $p_input == "restart" ]
then
        echo "1、停止/启动：服务"
        stop_all_server
        run_all_server
elif [ $p_input == "log" ]
then
        echo "1、查看日志：log"
        cat_log
elif [ $p_input == "cat" ]
then
        echo "1、查看服务：server"   
        cat_server
elif [ $p_input == "mysql" ]
then
        echo "1、链接服务：mysql"  
        con_mysql  
elif [ $p_input == "mock_base" ]
then
        echo "1、mock 基础服务"  
        mock_base
elif [ $p_input == "mock_user" ]
then
        echo "1、mock 业务服务"  
        mock_user
elif [ $p_input == "mock_assert" ]
then
        echo "1、mock_assert 结果"
        mock_assert
elif [ $p_input == "scp_master" ]
then
        echo "1、拷贝文件到其他地方：scp"  
        scp_master
elif [ $p_input == "scp_815" ]
then
        echo "1、拷贝文件到其他地方：scp"  
        scp_815        
elif [ $p_input == "scp_830" ]
then
        echo "1、拷贝文件到其他地方：scp"  
        scp_830        
elif [ $p_input == "check" ]
then
        echo "1、check 服务：api"  
        check_api_server
        echo "2、check 服务：worker"  
        check_worker_server
        echo "3、check 服务：master"  
        check_master_server
        echo "4、check 服务：worker"  
        check_alert_server
elif [ $p_input == "allstop" ]
then
        stop_all_server
elif [ $p_input == "restart_day" ]
then
        read -p "hi, 请输入启动哪天: today/0613/0614 " p_date
        if [ $p_date != "today" ]
        then
                today=$p_date
        fi
        echo "当前" $today
        stop_all_server
        run_all_server
elif [ $p_input == "stop" ]
then
    read -p "hi, 请输入停止的服务：api-server | worker-server | master-server " server
    hanld_server stop $server
elif [ $p_input == "start" ]
then
    read -p "hi, 请输入启动的服务：api-server | worker-server | master-server " server
    hanld_server start $server
elif [ $p_input == "tar" ]
then 
    tar_file
fi
      
}
 
p_input=$1  
log_server=$2
init_zk
define_param
main_run
