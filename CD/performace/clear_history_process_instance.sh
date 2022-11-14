#!/bin/bash

deleteProcessInstance="delete from sprint_2209.t_ds_process_instance"
deleteTaskInstance="delete from sprint_2209.t_ds_task_instance"
deleteCommand="delete from sprint_2209.t_ds_command"
deleteErrorCommand="delete from sprint_2209.t_ds_error_command"

mysql -hds-test-mysql.cwkplpl0hwlq.ap-southeast-1.rds.amazonaws.com -uadmin -padminadmin -D "sprint_2209" -e "$deleteProcessInstance;$deleteTaskInstance;$deleteCommand;$deleteErrorCommand;"
sleep 1s

