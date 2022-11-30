#!/bin/bash


########################
# 说明：初始化配置
########################
function init_param(){

# 数据库信息
mysql_ip="ctyun7"
mysql_user="root"
mysql_passwd="root@123"
mysql_database="whalescheduler"
mysql_port="3306"

# 插入信息
insert="insert into $mysql_database.t_ds_command(command_type,process_definition_code,process_definition_version,task_depend_type,failure_strategy,start_time,executor_id,update_time,process_instance_priority,worker_group,environment_code,dry_run,warning_type,warning_group_id,schedule_time)"
command_type=0
task_dependent_type=2
failure_strategy=1
dry_run=0 # 0 means real run, 1 means dry run
execute_user_id=1
schedule_time=null
value="($command_type,$process_definition_code,$process_definition_version,$task_dependent_type,$failure_strategy,now(),$execute_user_id,now(),2,default,-1,$dry_run,0,0,$schedule_time)"
values="$value"

}

########################
# 说明：批量构造数据
########################
function batch_create(){
# 提示
#if [ $# -eq 0 ];
#then
#  echo "./batch_insert_command.sh process_definition_code=1 process_definition_version=2 batch_size=10 batch_number=10"
#  exit 1
#fi

echo "code=$process_definition_code, version=$process_definition_version, batch_number=$batch_number"

# 批量构造数据
for i in $(seq 1 $batch_size)
do
  values="$values,$value"
done

insertCommand="$insert values $values;"
echo "$insertCommand"

}

########################
# 说明：批量插入
########################
function batch_insert(){

# 批量插入
for i in $(seq 1 $batch_number)
do
  echo $i
  # echo "mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e $insertCommand"
  mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D "$mysql_database" -e "$insertCommand"
  sleep 1s
done

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
# 说明：插入数据
########################
function batch_clear(){

deleteProcessInstance="delete from t_ds_process_instance"
deleteTaskInstance="delete from t_ds_task_instance"
deleteCommand="delete from t_ds_command"
deleteErrorCommand="delete from t_ds_error_command"
echo "mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e \"$deleteProcessInstance;$deleteTaskInstance;$deleteCommand;$deleteErrorCommand;\""
mysql -h$mysql_ip -u$mysql_user -p$mysql_passwd -D $mysql_database -e "$deleteProcessInstance;$deleteTaskInstance;$deleteCommand;$deleteErrorCommand;"
sleep 1s


}

main_run(){

if [ $p_input == "tips" ]
then
       tips
elif [ $p_input == "run" ]
then
       read -p "hi, 工作流定义code: " process_definition_code
       read -p "hi, 工作流定义version: " process_definition_version
       read -p "hi, 工作流定义循环次数: " batch_number
       read -p "hi, 工作流定义单次数量: " batch_size
       init_param
       batch_create
       batch_insert
elif [ $p_input == "clear" ]
then
       init_param
       batch_clear
elif [ $p_input == "mysql" ]
then
       init_param
       con_mysql
fi

}

p_input=$1
main_run
