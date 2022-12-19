#!/bin/bash
########################
# 说明：部署前，环境 checklist
########################

function init_param(){

# 磁盘定义
read_test='vda1'

# 结果名称
RESULTFILE="InstallCheck-`hostname`-`date +%Y%m%d`.txt"

zk_ip="ctyun6"
zk_port=":2181"
mysql_ip="ctyun6"
mysql_user="root"
mysql_passwd="root@123"
mysql_database="whalescheduler"
mysql_port="3306"

# 定义读取环境
#env_file=$tool_env_conf_path/env_file

#while read line;do
#    eval "$line"
#done < $env_file

}


function get_sys_info(){
    echo "******************************************************* 系统检查 *******************************************************"
	  CPU_nums=$(cat /proc/cpuinfo | grep 'core id' | wc -l)
	  MEM_nums=$(free -g|grep Mem|awk '{print $2}')
	  centosVersion=$(awk '{print $(NF-1)}' /etc/redhat-release)
	  echo "*******  1. centos_version_check: $centosVersion ******* "  >> $RESULTFILE

	  if [[ $CPU_nums -ge 7 ]];then
           echo "******* 2. cpu_check is pass, cpu should bigger than 8, real cpu is: $CPU_nums *******"  >> $RESULTFILE
      else
           echo "******* 2. cpu_check is fail, cpu should bigger than 8, real cpu is: $CPU_nums *******"  >> $RESULTFILE
      fi

	  if [[ $MEM_nums -ge 15 ]];then
           echo "******* 3. memory_check is pass, memory should bigger than 16g, real memory is: $MEM_nums *******"  >> $RESULTFILE
      else
           echo "******* 3. memory_check is fail, memory should bigger than 16g, real memory is: $MEM_nums *******"  >> $RESULTFILE
      fi

}


function get_disk_rw_test(){
    echo -e "\033[1;32m******************************************************* 数据盘性能检测 *******************************************************\033[0m"
    dd if=/dev/$read_test of=/dev/null iflag=direct,nonblock bs=128MB count=10 2> disk_read_res.txt
    dd if=/dev/zero of=/dev/$read_test oflag=direct,nonblock bs=128MB count=10 2> disk_write_res.txt

    disk_read_check=`cat disk_read_res.txt| grep MB | awk '{print $8}'`
    disk_write_check=`cat disk_write_res.txt| grep MB | awk '{print $8}'`

	#if [[ $disk_read_check -ge 100 ]];then
	if [ `echo "$disk_read_check > 100"|bc` -eq 1 ];then
        echo "******* 4. disk_read_check is pass, disk_read_check should bigger than 100MB/s, real disk_read_check is: $disk_read_check *******"  >> $RESULTFILE
    else
        echo "******* 4. disk_read_check is fail, disk_read_check should bigger than 100MB/s, real disk_read_check is: $disk_read_check *******"  >> $RESULTFILE
    fi

	#if [[ $disk_write_check -ge 100 ]];then
	if [ `echo "$disk_write_check > 100"|bc` -eq 1 ];then
        echo "******* 5. disk_write_check is pass, disk_write_check should bigger than 100MB/s, real disk_write_check is: $disk_write_check *******"  >> $RESULTFILE
    else
        echo "******* 5. disk_write_check is fail, disk_write_check should bigger than 100MB/s, real disk_write_check is: $disk_write_check *******"  >> $RESULTFILE
    fi




}

function get_disk_status(){
    echo -e "\033[1;32m******************************************************* data 目录挂载情况 *******************************************************\033[0m"
    tmp=`df -h /data | grep data | awk '{print $4}'`
    data_size=${tmp: : -1}


	if [[ $data_size -ge 400 ]];then
        echo "******* 6. data_size is pass, data_size should bigger than 400G, real data_size is: $data_size *******"  >> $RESULTFILE
    else
         echo "******* 6. data_size is fail, data_size should bigger than 400G, real data_size is: $data_size *******"  >> $RESULTFILE
    fi

}


function get_mysql(){
  echo -e "\033[1;32m******************************************************* mysql网络check *******************************************************\033[0m"
  mysql_telnet=`telnet $mysql_ip $mysql_port | grep Escape | awk '{print $1}'`
  mysql_ping=`ping -c 2 $mysql_ip | grep received | awk '{print $4}'`

  # telnet 返回等于 Escape
  if [[ $mysql_telnet -eq 'Escape' ]];then
     echo "******* 7. mysql_telnet is pass, mysql_telnet: $mysql_telnet *******"  >> $RESULTFILE
  else
     echo "******* 7. mysql_telnet is fail, mysql_telnet: $mysql_telnet *******"  >> $RESULTFILE
  fi

  # ping 返回received 数量大于1
  if [[ $mysql_ping -ge 1 ]];then
     echo "******* 8. mysql_ping is pass, mysql_ping: $mysql_ping *******"  >> $RESULTFILE
  else
     echo "******* 8. mysql_ping is fail, mysql_ping: $mysql_ping *******"  >> $RESULTFILE
  fi

}

function set_hosts(){
    echo -e "\033[1;32m******************************************************* host 配置 *******************************************************\033[0m"
    for ip in ${addr_list[@]}
    do
      for host_ip in ${hosts_list[@]}
      do
          ssh $ip 'sed -i "$a\"$host_ip /etc/hosts'
      done
      cat /etc/hosts
    done
}

function set_ssh(){

  echo -e "\033[1;32m******************************************************* ssh 配置 *******************************************************\033[0m"
  for ip in ${addr_list[@]}
  do
    ssh $ip 'ssh-keygen -t rsa -N '' -f id_rsa -q'
    cat ~/.ssh/id_rsa.pub
  done

}

function set_start_user(){
  echo -e "\033[1;32m******************************************************* 创建启动用户 whalescheduler *******************************************************\033[0m"
  sed  -i 's/#%wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers
  useradd $start_user
  usermod -G wheel $start_user
  id $start_user

}

function set_tenant_user(){
  echo -e "\033[1;32m******************************************************* 创建租户 ops *******************************************************\033[0m"
  useradd $tenant_user
  usermod -G $start_user $tenant_user
  id $tenant_user

}

function set_time_zone(){
  echo -e "\033[1;32m******************************************************* 设置时区 *******************************************************\033[0m"
  echo "ZONE=Asia/Shanghai" >> /etc/sysconfig/clock
  rm -f /etc/localtime
  clock_file="/usr/share/zoneinfo/Asia/Shanghai"
  if [ -f "$clock_file" ];then
    echo "文件存在，输出到/etc/localtime"
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  else
    echo "文件不存在"
  fi
  date
}

function jdk_check(){
    echo -e "\033[1;32m******************************************************* jdk检查 *******************************************************\033[0m"
    tmp=`java -version  2>&1 | grep version | awk '{print $3}'`
    java_version=${tmp:1:3}
    exp="1.7"

    # java 版本大于1.7
    if [ `echo "$java_version > $exp"|bc` -eq 1 ];then
       echo "******* 9. java_version is pass, java_version should bigger than 1.7, real java_version is: $java_version *******"  >> $RESULTFILE
    else
       echo "******* 9. java_version is fail, java_version should bigger than 1.7, real java_version is: $java_version *******"  >> $RESULTFILE
    fi


}

function time_check(){
    echo -e "\033[1;32m******************************************************* time检查 *******************************************************\033[0m"
    time_check=`/usr/sbin/ntpdate -u cn.pool.ntp.org| awk '{print $10}'`

    # 时钟差异小于1秒
    if [ `echo "$time_check < 1"|bc` -eq 1 ];then
       echo "******* 10. time_check is pass, time_check should smaller than 1, real time_check is: $time_check *******"  >> $RESULTFILE
    else
       echo "******* 10. time_check is fail, time_check should smaller than 1, real time_check is: $time_check *******"  >> $RESULTFILE
    fi

    hwclock -w
    hwclock -r
}

main_check(){

        init_param
        get_sys_info
        get_disk_rw_test
        get_disk_status
        get_mysql
        jdk_check
        time_check

}

main_check