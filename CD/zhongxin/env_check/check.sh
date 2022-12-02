########################
# 说明：部署前，环境 checklist
########################

function init_param(){
read_test='vda1'
write_test='vda1'
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
source /etc/profile
[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本！" && exit 1
centosVersion=$(awk '{print $(NF-1)}' /etc/redhat-release)
VERSION=`date +%F`

# 日志相关
RESULTFILE="InstallCheck-`hostname`-`date +%Y%m%d`.txt"

# 判断CPU是否符合要求
memory=`free -m | egrep Mem | awk '{printf("%.0f\n",$2/1024)}'`
cpuxian=`grep "processor" /proc/cpuinfo | wc -l`

# 服务列表
#addr_list=("zx36" "zx37" "zx38" "zx39" "zx40" "zx41" "zx123" "zx124" "zx200" "zx201" "zx202" "zx89" "zx91")
addr_list_1=("zx36" "zx37")
addr_list_2=("zx36" "zx37")
hosts_list=("10.0.0.1\tzx1" "10.0.0.2\tzx2")


# 定义数据库及zk连接
mysql_ip="zx110"
zk_ip="zx36:2181,zx37:2181,zx38:2181"
mysql_user="admin"
mysql_passwd="scheduler@2022"
mysql_database="whalescheduler"
mysql_port="15018"

# 定义用户
start_user="whalescheduler"
tenant_user="ops"

}


function get_sys_info(){
    echo ""
	  CPU_nums=$(cat /proc/cpuinfo | grep 'core id' | wc -l)
	  MEM_nums=$(free -g|grep Mem|awk '{print $2}')G
    echo "基本配置："
	echo ""
    echo "详细配置见下方内容"
}

function get_cpu_status(){
    echo -e "\033[1;32m*******************************************************CPU检查*******************************************************\033[0m"
    Physical_CPUs=$(grep "physical id" /proc/cpuinfo| sort | uniq | wc -l)
    Virt_CPUs=$(grep "processor" /proc/cpuinfo | wc -l)
    CPU_Kernels=$(grep "cores" /proc/cpuinfo|uniq| awk -F ': ' '{print $2}')
    CPU_Type=$(grep "model name" /proc/cpuinfo | awk -F ': ' '{print $2}' | sort | uniq)
    CPU_Arch=$(uname -m)
    CPU_OPS=$(lscpu|grep Flags)
    echo "物理CPU个数:$Physical_CPUs"
    echo "逻辑CPU个数:$Virt_CPUs"
    echo "每CPU核心数:$CPU_Kernels"
    echo "    CPU型号:$CPU_Type"
    echo "    CPU架构:$CPU_Arch"
    echo "    CPU特性:$CPU_OPS"
}

function get_mem_status(){
    echo  -e "\033[1;32m*******************************************************内存检查*******************************************************\033[0m"
    if [[ $centosVersion < 7 ]];then
        free -mo
    else
        free -h
    fi
}
function get_disk_rw_test(){
    echo -e "\033[1;32m*******************************************************数据盘性能检测*******************************************************\033[0m"
    for i in $read_test;
    do
            echo read test $i >> $RESULTFILE;
            dd if=/dev/$i of=/dev/null iflag=direct,nonblock bs=128MB count=10 2>> $RESULTFILE
            dd if=/dev/$i of=/dev/null iflag=direct,nonblock bs=128MB count=10 2>> $RESULTFILE
            dd if=/dev/$i of=/dev/null iflag=direct,nonblock bs=128MB count=10 2>> $RESULTFILE
            dd if=/dev/$i of=/dev/null iflag=direct,nonblock bs=128MB count=10 2>> $RESULTFILE
            dd if=/dev/$i of=/dev/null iflag=direct,nonblock bs=128MB count=10 2>> $RESULTFILE
    done

    for i in $write_test;
    do
            echo write test $i >> $RESULTFILE;
            dd if=/dev/zero of=/dev/$i oflag=direct,nonblock bs=128MB count=10 2>> $RESULTFILE
            dd if=/dev/zero of=/dev/$i oflag=direct,nonblock bs=128MB count=10 2>> $RESULTFILE
            dd if=/dev/zero of=/dev/$i oflag=direct,nonblock bs=128MB count=10 2>> $RESULTFILE
            dd if=/dev/zero of=/dev/$i oflag=direct,nonblock bs=128MB count=10 2>> $RESULTFILE
            dd if=/dev/zero of=/dev/$i oflag=direct,nonblock bs=128MB count=10 2>> $RESULTFILE
    done
}

function get_disk_status(){
    echo -e "\033[1;32m******************************************************* data 目录挂载情况 *******************************************************\033[0m"
    df -h /data
}

function get_port_status(){
    echo -e "\033[1;32m******************************************************* 端口检测 *******************************************************\033[0m"
    for ip_1 in ${addr_list_1[@]}
    do
        ssh $ip_1 'telnet $ip 22'
        ssh $ip_1 'telnet $ip 1234'
        ssh $ip_1 'telnet $ip 1234'
        ssh $ip_1 'telnet $ip 5678'
        ssh $ip_1 'telnet $ip 5679'
    done
}

function get_mysql(){
  telnet $mysql_ip $mysql_port
  ping $mysql_ip
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
    echo -e "\033[1;32m*******************************************************jdk检查*******************************************************\033[0m"
    java -version 2>/dev/null
    if [ $? -eq 0 ];then
	 echo $JAVA_HOME;
    fi
}

main_check(){

        init_param
        echo "===== 1、系统/cpu/内存/磁盘 ====="
        get_sys_info
        get_cpu_status
        get_mem_status
        get_disk_rw_test
        get_disk_status
        echo "===== 2、端口/mysql ====="
        get_port_status
        get_mysql
        echo "===== 3、三方服务：jdk ===== "
        jdk_check

}

main_set(){
        echo "===== 1、hosts/ssh ====="
        set_hosts
        set_ssh
        echo "===== 2、用户权限 ====="
        set_user_whalescheduler
        set_user_ops
        echo "===== 3、时区/ntp ====="
        set_time
}
main_check