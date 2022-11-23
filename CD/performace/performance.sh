#!/bin/bash


########################
# 说明：初始化配置
########################
function init_param(){

# 数据库信息
mysql_ip="zx110"
mysql_user="admin"
mysql_passwd="scheduler@2022"
mysql_database="whalescheduler"
mysql_port="15018"

# 插入信息
insert="insert into $mysql_database.t_ds_command(command_type,process_definition_code,process_definition_version,task_depend_type,failure_strategy,start_time,executor_id,update_time,process_instance_priority,worker_group,environment_code,dry_run,warning_type,warning_group_id,schedule_time)"
process_definition_code=$1
process_definition_version=$2
batch_number=$3
batch_size=$4
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
if [ $# -eq 0 ];
then
  echo "./batch_insert_command.sh process_definition_code=1 process_definition_version=2 batch_size=10 batch_number=10"
  exit 1
fi

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
# 说明：统计相关稳定性指标
########################
function batch_insert(){

# 批量插入
for i in $(seq 1 $batch_number)
do
  echo $i
  mysql -h$mysql_ip -$mysql_user -$mysql_passwd -D "$mysql_database" -e "$insertCommand"
  sleep 1s
done

}

init_param
batch_create
batch_insert