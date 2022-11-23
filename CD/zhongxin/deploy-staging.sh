#!/bin/bash

########################
# 说明：定义参数
########################
define_param(){

# 定义主目录
work_father_path="/data/release/"

# 定义DB目录
work_db_path="/data/release/DB/"

# 中信测试环境
addr_list=("zx32" "zx33" "zx3" "zx196" "zx166" "223")
api_list=("zx32" "zx33")
alert_list=("zx32" "zx33")
master_list=("zx32" "zx33")
worker_list=("zx32" "zx33" "zx3" "zx196" "zx166" "223")

mysql_ip="zx_sql"
zk_ip="zx32:2181"
mysql_user="admin"
mysql_passwd="123qqq...A"
mysql_database="300beta"
mysql_port="15052"

# 工具/工作 目录
tool_path=$work_father_path"tool/"
work_path=$work_father_path$today


# 定义运维脚本
deploy_sh=$tool_path"deploy.sh"

# 定义压力脚本
performace_sh=$tool_path"/batch_insert_command.sh"
performace_clear_sh=$tool_path"/clear_history_process_instance.sh"
performace_instance="7491908079552 2 10 600"
performace_collect_sh=$tool_path"/count_sql.sh"


# 待替换文件
p_mysql_jar=$tool_path/mysql-connector-java-8.0.16.jar
p_ojbc_jar=$tool_path/ojdbc8.jar
p_common_conf=$tool_path/common.properties
p_customer_conf=$tool_path/customer-config.yaml


# packge包名定义
packge_tar=whalescheduler-1.0-SNAPSHOT-bin.tar.gz
packge=whalescheduler-1.0-SNAPSHOT-bin



}

########################
# 说明：获取当前目录下最新日期
########################
get_current_day(){
    day=$1
    if [ $day == "today" ]
    then
        today=`date +%m%d`
        echo "今日："$today
    elif [ $day == "recent_day" ]
    then
        today=`ls -Art |grep ^[0-9].*[0-9]$ | tail -n 1`
        echo "最新："$today
    else
        echo "非法日期"
    fi
}

########################
# 说明：deploy环境变量生效
########################
source_deploy(){
echo "========== source 环境变量 ========== "
sed -i '$a\alias deploy="/data/release/tool/deploy.sh"' /etc/profile
source /etc/profile
}




########################
# 说明：性能压测脚本
########################
performace_run(){
ssh aws1 "sh $performace_clear_sh"
ssh aws1 "sh $performace_sh $performace_instance"
}




########################
# 说明：性能压测脚本
########################
performace_collect(){
ssh aws1 "sh $performace_collect_sh $commad"
}


########################
# 说明：打印启动参数
########################
echo_init_param(){
echo "全部参数"
echo "tool目录："$tool_path
echo "today目录："$today
echo "work_path目录："$work_path
echo "p_mysql_jar目录："$p_mysql_jar
echo "p_ojbc_jar目录："$p_ojbc_jar
echo "p_customer_conf目录:  "$p_customer_conf
echo "mysql_ip地址："$mysql_ip
echo "zk_ip地址："$zk_ip
echo "mysql_user："$mysql_user
echo "mysql_passwd："$mysql_passwd
echo "mysql_database："$mysql_database
echo "mysql_port: "$mysql_port

}


########################
# 说明：多台机器执行运维脚本
# 例：sh ws_sprint_2209.sh allstop
########################
remote_all_exec_command(){

for ip in ${addr_list[@]}
do
	 echo "ssh "$ip" "$deploy_sh" "$commad
     ssh $ip sh $deploy_sh $commad
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
	echo sh" "$ip" "sh" "$deploy_sh" "allstop
	ssh $ip sh $deploy_sh allstop
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
ssh $ip "sh $deploy_sh start api-server"
done

for ip in ${worker_list[@]}
do
ssh $ip "sh $deploy_sh start worker-server"
done

for ip in ${master_list[@]}
do
ssh $ip "sh $deploy_sh start master-server"
done

for ip in ${alert_list[@]}
do
ssh $ip "sh $deploy_sh start alert-server"
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
        echo ssh $ip \"sed -i \'s/-server/-server -Duser.timezone=GMT+08/g\' $work_path/api-server/bin/start.sh\"
        echo ssh $ip \"sed -i \'s/-server/-server -Duser.timezone=GMT+08/g\' $work_path/master-server/bin/start.sh\"
        echo ssh $ip \"sed -i \'s/-server/-server -Duser.timezone=GMT+08/g\' $work_path/worker-server/bin/start.sh\"
        echo ssh $ip \"sed -i \'s/-server/-server -Duser.timezone=GMT+08/g\' $work_path/alert-server/bin/start.sh\"
        ssh $ip  "sed -i 's/-server/-server -Duser.timezone=GMT+08/g' $work_path/api-server/bin/start.sh"
        ssh $ip  "sed -i 's/-server/-server -Duser.timezone=GMT+08/g' $work_path/master-server/bin/start.sh"
        ssh $ip  "sed -i 's/-server/-server -Duser.timezone=GMT+08/g' $work_path/worker-server/bin/start.sh"
        ssh $ip  "sed -i 's/-server/-server -Duser.timezone=GMT+08/g' $work_path/alert-server/bin/start.sh"
}


########################
# 说明：解压文件，命名为今天日期 例：1101/
########################
tar_file(){

pwd
cd $work_father_path
rm -rf $today
tar -zxf $packge_tar
mv $packge $today

}



########################
# 说明：数据库配置
########################
init_server(){


# 修改配置
cd $work_path/bin/env/
sed  -i 's/localhost:2181/'$zk_ip'/g' whalescheduler_env.sh
sed -i '$a\export DATABASE="mysql"' whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_DRIVER_CLASS_NAME="com.mysql.jdbc.Driver"' whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_URL="jdbc:mysql://'$mysql_ip':'$mysql_port'/'$mysql_database'?useUnicode=true&characterEncoding=UTF-8&allowMultiQueries=true"' whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_USERNAME='$mysql_user whalescheduler_env.sh
sed -i '$a\export SPRING_DATASOURCE_PASSWORD='$mysql_passwd whalescheduler_env.sh

}


########################
# 说明：统计相关稳定性指标
########################
count_sql(){

count="select count(1) as task_total from t_ds_task_instance;"
start_time_avg="select start_time as start_time_avg, count(1) from t_ds_task_instance group by start_time order by count(1) desc limit 3;"
end_time_avg="select end_time as end_time_avg,count(1) from t_ds_task_instance group by end_time order by count(1) desc limit 3;"
tps_avg="select avg(a) as tps_avg from (select count(1) as a,start_time from t_ds_task_instance group by start_time order by count(1)) as tmp;"

echo "========== 2022-11-17 18:17 开始运行，目前task总量：========== "
echo "mysql -h"$mysql_ip" -u"$mysql_user+" -p"$mysql_passwd" -D "$mysql_database" -e "$count
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e "$count"
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e "$start_time_avg"
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e "$end_time_avg"
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e "$tps_avg"
echo "========== 当前ctyun7 服务/磁盘 ========== "
ssh ctyun7 "deploy cat"
ssh ctyun7 "df -h /data"
echo "========== 当前ctyun9 服务/磁盘 ========== "
ssh ctyun9 "deploy cat"
ssh ctyun9 "df -h /data"

}


########################
# 说明：清理 command \ error_commad \ process_instance\ task_instance
########################
delete_sql(){
deleteCommand="delete from t_ds_command"
deleteErrorCommand="delete from t_ds_error_command"
deleteProcessInstance="delete from t_ds_process_instance"
deleteTaskInstance="delete from t_ds_task_instance"

mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e "$deleteCommand"
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e "$deleteErrorCommand"
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e "$deleteProcessInstance"
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e "$deleteTaskInstance"

}

########################
# 说明：初始化 mysql
########################
init_mysql(){

init_hdfs
sql_path1=$work_path/tools/conf/sql/dolphinscheduler_mysql.sql
sql_path2=$work_path/tools/conf/sql/whalescheduler_mysql.sql
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
cd $work_path
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
sh $work_path/bin/whalescheduler-daemon.sh stop api-server
sh $work_path/bin/whalescheduler-daemon.sh stop master-server
sh $work_path/bin/whalescheduler-daemon.sh stop worker-server
sh $work_path/bin/whalescheduler-daemon.sh stop alert-server
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
echo "$work_path/bin/whalescheduler-daemon.sh start api-server"
sh $work_path/bin/whalescheduler-daemon.sh start api-server
sh $work_path/bin/whalescheduler-daemon.sh start master-server
sh $work_path/bin/whalescheduler-daemon.sh start worker-server
sh $work_path/bin/whalescheduler-daemon.sh start alert-server

}


########################
# 说明：检查api服务启动
########################
check_api_server(){

    # 查看api log
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

########################
# 说明：检查worker服务启动
########################
check_worker_server(){

    # 查看worker log
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

########################
# 说明：检查master服务启动
########################
check_master_server(){

    # 查看master log
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

########################
# 说明：检查alert服务启动
########################
check_alert_server(){

    # 查看alert log
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


########################
# 说明：log查看
########################
cat_log(){


echo "hi, 请输入监控日志: api|master|worker|alert "

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
# 例：mysqldump
########################
mysql_dump(){

echo "mysql -h" $mysql_ip "-u" $mysql_user " -P" $mysql_port " -p " $mysql_database
mysqldump -h$mysql_ip -u$mysql_user -P$mysql_port -p $mysql_database > work_db_path/$mysql_database.sql

}


########################
# 说明：mock 基础服务
########################
mock_base(){

# 基础T0冒烟
cd $tool_path/data
echo "基础mock：开始"
newman run 01-基础用例.postman_collection.json --delay-request 10 --working-dir /home/wenzixin/postman/data/jar_floder/ -e test_env.postman_environment.json -r cli,html | tee mock.txt
echo "基础mock：结束"

}


########################
# 说明：mock 业务服务
########################
mock_user(){

# 业务T1冒烟
cd $tool_path/data
echo "业务mock：开始"
newman run 02-业务用例.postman_collection.json --delay-request 10 --working-dir /home/wenzixin/postman/data/jar_floder/ -e test_env.postman_environment.json -r cli,html | tee mock.txt
echo "业务mock：结束"
}

########################
# 说明：mock 断言
########################
mock_assert(){

        # 冒烟结果检查
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

########################
# 说明：部署后，功能checklist
########################
func_check_list(){

        echo "=====1、web访问是否跳转到：中信重定向cas认证？====="
        echo "=====2、shell 是否正常运行？====="
        echo "=====3、sync 是否正常同步？====="
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


if [ $p_input == "tips" ]
then
       tips
elif [ $p_input == "source" ]
then
       source_deploy
elif [ $p_input == "param" ]
then
      echo_init_param
elif [ $p_input == "count_sql" ]
then
        count_sql
elif [ $p_input == "delete_sql" ]
then
        delete_sql
elif [ $p_input == "per_run" ]
then
        performace_run
elif [ $p_input == "per_col" ]
then
		read -p "输入性能结果命名 " commad
        performace_collect $commad
elif [ $p_input == "remote_all_exec_command" ]
then
		read -p "多台机器需要执行命令 " commad
        remote_all_exec_command $commad
elif [ $p_input == "remote_all_cp_file" ]
then
        read -p "hi, 请输入需要拷贝文件: " file
        remote_all_cp_file $file
elif [ $p_input == "remote_all_start" ]
then
        remote_all_start
elif [ $p_input == "conf" ]
then
        echo "1、初始化配置：conf"
        get_current_day "today"
        define_param
        tar_file
        init_server
elif [ $p_input == "init_mysql" ]
then
        echo "禁止初始化mysql"
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
elif [ $p_input == "stop" ]
then
    hanld_server stop $log_server
elif [ $p_input == "start" ]
then

    hanld_server start $log_server
fi

}


p_input=$1
log_server=$2
get_current_day "recent_day"
define_param
main_run
