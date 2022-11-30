#!/bin/bash


if [ $# -eq 0 ];
then
  echo "./batch_insert_command.sh process_definition_code=1 process_definition_version=2 batch_size=10 batch_number=10"
  exit 1
fi

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
echo "code=$process_definition_code, version=$process_definition_version, batch_number=$batch_number"

insert="insert into sprint_2209.t_ds_command(command_type,process_definition_code,process_definition_version,task_depend_type,failure_strategy,start_time,executor_id,update_time,process_instance_priority,worker_group,environment_code,dry_run,warning_type,warning_group_id,schedule_time)"
value="($command_type,$process_definition_code,$process_definition_version,$task_dependent_type,$failure_strategy,now(),$execute_user_id,now(),2,default,-1,$dry_run,0,0,$schedule_time)"
values="$value"
for i in $(seq 1 $batch_size)
do
values="$values,$value"
done

insertCommand="$insert values $values;"

echo "$insertCommand"

for i in $(seq 1 $batch_number)
do
echo $i
mysql -hds-test-mysql.cwkplpl0hwlq.ap-southeast-1.rds.amazonaws.com -uadmin -padminadmin -D "sprint_2209" -e "$insertCommand"
sleep 1s
done
