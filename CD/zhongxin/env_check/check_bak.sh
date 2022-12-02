#!/bin/bash
#############################
#Version:20191231
#
#############################
read_test=''
write_test=''
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
source /etc/profile
[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本！" && exit 1
centosVersion=$(awk '{print $(NF-1)}' /etc/redhat-release)
VERSION=`date +%F`
#日志相关
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
[ -f $PROGPATH ] && PROGPATH="."
LOGPATH="$PROGPATH/log"
[ -e $LOGPATH ] || mkdir $LOGPATH
RESULTFILE="$LOGPATH/InstallCheck-`hostname`-`date +%Y%m%d`.txt"
#判断CPU是否符合要求
memory=`free -m | egrep Mem | awk '{printf("%.0f\n",$2/1024)}'`
cpuxian=`grep "processor" /proc/cpuinfo | wc -l`

function packget_update(){
	yum update nc -y
}

function error_info(){
    echo -e "\033[1;32m*******************************************************服务器兼容问题*******************************************************\033[0m"

if [ ${cpuxian} -lt 16 -o ${memory} -lt 30 ];then
        echo -e "\033[1;31m cpu线程数不符合方舟安装要求,最低要求cpu线程数16，内存最低要求32g,当前CPU线程为${cpuxian},当前内存是${memory}g \033[0m";
fi

if [ `lscpu|grep Flags|grep -i -w sse4_2 |wc -l` == 0  ];then
	echo -e "\033[1;31m cpu不支持sse4.2指令集，无法支持kudu \033[0m";
fi

if [ `lscpu|grep Flags|grep -i -w avx |wc -l` == 0  ];then
        echo -e "\033[1;31m cpu不支持avx指令集，无法支持avx版本的pika \033[0m";
fi

for i in 25 465 587
do
	nc -zv smtp.analysys.com.cn $i || echo -e "\033[1;31m 对外请求邮件端口 $i 无法连通。\033[0m";
done

######第三方push接口检查
nc -zv api.jpush.cn 80 || echo -e "\033[1;31m 极光推送https://api.jpush.cn/v3/push无法连通。\033[0m"
nc -zv api.tuisong.baidu.com 80 || echo -e "\033[1;31m 百度推送http://api.tuisong.baidu.com无法连通。\033[0m"
nc -zv api.tuisong.baidu.com 443 || echo -e "\033[1;31m 百度推送https://api.tuisong.baidu.com无法连通。\033[0m"
nc -zv restapi.getui.com 443 || echo -e "\033[1;31m 个推https://restapi.getui.com/v1无法连通。\033[0m"
nc -zv api.xmpush.xiaomi.com 80 || echo -e "\033[1;31m 小米推送http://api.xmpush.xiaomi.com无法连通。\033[0m"
nc -zv api.xmpush.xiaomi.com 443 || echo -e "\033[1;31m 小米推送https://api.xmpush.xiaomi.com无法连通。\033[0m"
######
if [ `umask` -ne 0022 ];then
        echo -e "\033[1;31m umask不等于0022 \033[0m";
fi
    echo -e "\033[1;32m*******************************************************以下是详细信息*******************************************************\033[0m"
}

function version(){
    echo ""
    echo "系统检查脚本：Version $VERSION"
}
function sys_info(){
    echo ""
	CPU_nums=$(cat /proc/cpuinfo | grep 'core id' | wc -l)
	MEM_nums=$(free -g|grep Mem|awk '{print $2}')G
    echo "基本配置："
	echo ""
    echo "详细配置见下方内容"
}
function diskrwtest(){
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
function getCpuStatus(){
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
function getMemStatus(){
    echo  -e "\033[1;32m*******************************************************内存检查*******************************************************\033[0m"
    if [[ $centosVersion < 7 ]];then
        free -mo
    else
        free -h
    fi
}
function getDiskStatus(){
    echo -e "\033[1;32m*******************************************************磁盘挂载使用检查*******************************************************\033[0m"
    df -hiP | sed 's/Mounted on/Mounted/'> /tmp/inode
    df -hTP | sed 's/Mounted on/Mounted/'> /tmp/disk 
    join -1 7 -2 6 /tmp/disk /tmp/inode | awk '{print $1,$2,"|",$3,$4,$5,$6,"|",$8,$9,$10,$11,"|",$12}'| column -t
	
    echo ""
    echo -e "\033[1;32m*******************************************************磁盘个数检查*******************************************************\033[0m"
    fdisk -l | grep -i disk
}
function getServerBios(){
    echo -e "\033[1;32m******************************************************硬件厂商检查*******************************************************\033[0m"
    dmidecode | grep -A 10 'System Information'| grep -E "Manufacturer|Product Name" | sed 's/^[ \t]*//g'
    dmidecode | grep -i uuid | sed 's/^[ \t]*//g'
}
function getSystemStatus(){
    echo -e "\033[1;32m*******************************************************系统检查 *******************************************************\033[0m"
    if [ -e /etc/sysconfig/i18n ];then
        default_LANG="$(grep "LANG=" /etc/sysconfig/i18n | grep -v "^#" | awk -F '"' '{print $2}')"
    else
        default_LANG=$LANG
    fi
    export LANG="en_US.UTF-8"
    Release=$(cat /etc/redhat-release 2>/dev/null)
    Kernel=$(uname -r)
    OS=$(uname -o)
    Hostname=$(uname -n)
    SELinux=$(/usr/sbin/sestatus | grep "SELinux status: " | awk '{print $3}')
    LastReboot=$(who -b | awk '{print $3,$4}')
    uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
    sys_umask=$(umask)
    echo "     系统：$OS"
    echo " 发行版本：$Release"
    echo "     内核：$Kernel"
    echo "   主机名：$Hostname"
    echo "  SELinux：$SELinux"
    echo "语言/编码：$default_LANG"
    echo " 当前时间：$(date +'%F %T')"
    echo " 最后启动：$LastReboot"
    echo " 运行时间：$uptime"
    echo "    umask：$sys_umask "
}
function getServiceStatus(){
    echo -e "\033[1;32m*******************************************************服务检查*******************************************************\033[0m"
    echo ""
    if [[ $centosVersion > 7 ]];then
        conf=$(systemctl list-unit-files --type=service --state=enabled --no-pager | grep "enabled")
        process=$(systemctl list-units --type=service --state=running --no-pager | grep ".service")
    else
        conf=$(/sbin/chkconfig | grep -E ":on|:启用")
        process=$(/sbin/service --status-all 2>/dev/null | grep -E "is running|正在运行")
    fi
    echo "服务配置"
    echo "--------"
    echo "$conf"  | column -t
    echo ""
    echo "正在运行的服务"
    echo "--------------"
    echo "$process"
}
function getAutoStartStatus(){
    echo -e "\033[1;32m*******************************************************自启动检查*******************************************************\033[0m"
    conf=$(grep -v "^#" /etc/rc.d/rc.local| sed '/^$/d')
    echo "$conf"
}
function getNetworkStatus(){
    echo -e "\033[1;32m*******************************************************网络检查*******************************************************\033[0m"
    if [[ $centosVersion < 7 ]];then
        /sbin/ifconfig -a | grep -v packets | grep -v collisions | grep -v inet6
    else
        #ip a
        for i in $(ip link | grep BROADCAST | awk -F: '{print $2}');do ip add show $i | grep -E "BROADCAST|global"| awk '{print $2}' | tr '\n' ' ' ;echo "" ;done
    fi
    for i in `ip a|grep -w inet|grep -v 127.0.0.1|awk '{print $NF}'`;do echo $i;ethtool $i|grep Speed;done
    GATEWAY=$(ip route | grep default | awk '{print $3}')
    DNS=$(grep nameserver /etc/resolv.conf| grep -v "#" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    echo "网关：$GATEWAY | DNS：$DNS"
ping -c 4 www.baidu.com >/dev/null 2>&1
if [ $? -eq 0 ];then
   echo "网络连接：可以连接外网" 
else
   echo "网络连接：无法连接外网"
fi 
}
function getListenStatus(){
    echo  -e "\033[1;32m*******************************************************监听检查*******************************************************\033[0m"
    TCPListen=$(ss -ntul | column -t)
    echo "$TCPListen"
}
function getCronStatus(){
    echo -e "\033[1;32m*******************************************************计划任务检查*******************************************************\033[0m"
    Crontab=0
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
        for user in $(grep "$shell" /etc/passwd| awk -F: '{print $1}');do
            crontab -l -u $user >/dev/null 2>&1
            status=$?
            if [ $status -eq 0 ];then
                echo "$user"
                echo "--------"
                crontab -l -u $user
                let Crontab=Crontab+$(crontab -l -u $user | wc -l)
                echo ""
            fi
        done
    done
    #计划任务
    find /etc/cron* -type f | xargs -i ls -l {} | column  -t
    let Crontab=Crontab+$(find /etc/cron* -type f | wc -l)
}
function getHowLongAgo(){
    datetime="$*"
    [ -z "$datetime" ] && echo `stat /etc/passwd|awk "NR==6"`
    Timestamp=$(date +%s -d "$datetime")  
    Now_Timestamp=$(date +%s)
    Difference_Timestamp=$(($Now_Timestamp-$Timestamp))
    days=0;hours=0;minutes=0;
    sec_in_day=$((60*60*24));
    sec_in_hour=$((60*60));
    sec_in_minute=60
    while (( $(($Difference_Timestamp-$sec_in_day)) > 1 ))
    do
        let Difference_Timestamp=Difference_Timestamp-sec_in_day
        let days++
    done
    while (( $(($Difference_Timestamp-$sec_in_hour)) > 1 ))
    do
        let Difference_Timestamp=Difference_Timestamp-sec_in_hour
        let hours++
    done
    echo "$days 天 $hours 小时前"
}
function getUserLastLogin(){
    username=$1
    : ${username:="`whoami`"}
    thisYear=$(date +%Y)
    oldesYear=$(last | tail -n1 | awk '{print $NF}')
    while(( $thisYear >= $oldesYear));do
        loginBeforeToday=$(last $username | grep $username | wc -l)
        loginBeforeNewYearsDayOfThisYear=$(last $username -t $thisYear"0101000000" | grep $username | wc -l)
        if [ $loginBeforeToday -eq 0 ];then
            echo "从未登录过"
            break
        elif [ $loginBeforeToday -gt $loginBeforeNewYearsDayOfThisYear ];then
            lastDateTime=$(last -i $username | head -n1 | awk '{for(i=4;i<(NF-2);i++)printf"%s ",$i}')" $thisYear" 
            lastDateTime=$(date "+%Y-%m-%d %H:%M:%S" -d "$lastDateTime")
            echo "$lastDateTime"
            break
        else
            thisYear=$((thisYear-1))
        fi
    done
}
function getUserStatus(){
    echo -e "\033[1;32m*******************************************************用户检查*******************************************************\033[0m"
    #/etc/passwd 最后修改时间
    pwdfile="$(cat /etc/passwd)"
    Modify=$(stat /etc/passwd | grep Modify | tr '.' ' ' | awk '{print $2,$3}')
    echo "/etc/passwd: $Modify ($(getHowLongAgo $Modify))"
    echo ""
    echo "特权用户"
    echo "--------"
    RootUser=""
    for user in $(echo "$pwdfile" | awk -F: '{print $1}');do
        if [ $(id -u $user) -eq 0 ];then
            echo "$user"
            RootUser="$RootUser,$user"
        fi
    done
    echo ""
    echo "用户列表"
    echo "--------"
    USERs=0
    echo "$(
    echo "用户名 UID GID HOME SHELL 最后一次登录"
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
        for username in $(grep "$shell" /etc/passwd| awk -F: '{print $1}');do
            userLastLogin="$(getUserLastLogin $username)"
            echo "$pwdfile" | grep -w "$username" |grep -w "$shell"| awk -F: -v lastlogin="$(echo "$userLastLogin" | tr ' ' '_')" '{print $1,$3,$4,$6,$7,lastlogin}'
        done
        let USERs=USERs+$(echo "$pwdfile" | grep "$shell"| wc -l)
    done
    )" | column -t
    echo ""
    echo "空密码用户"
    echo "----------"
    USEREmptyPassword=""
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
            for user in $(echo "$pwdfile" | grep "$shell" | cut -d: -f1);do
            r=$(awk -F: '$2=="!!"{print $1}' /etc/shadow | grep -w $user)
            if [ ! -z $r ];then
                echo $r
                USEREmptyPassword="$USEREmptyPassword,"$r
            fi
        done    
    done
    echo ""
    echo "相同ID的用户"
    echo "------------"
    USERTheSameUID=""
    UIDs=$(cut -d: -f3 /etc/passwd | sort | uniq -c | awk '$1>1{print $2}')
    for uid in $UIDs;do
        echo -n "$uid";
        USERTheSameUID="$uid"
        r=$(awk -F: 'ORS="";$3=='"$uid"'{print ":",$1}' /etc/passwd)
        echo "$r"
        echo ""
        USERTheSameUID="$USERTheSameUID $r,"
    done
}
function getPasswordStatus {
    echo -e "\033[1;32m*******************************************************密码检查*******************************************************\033[0m"
    pwdfile="$(cat /etc/passwd)"
    echo ""
    echo "密码过期检查"
    echo "------------"
    result=""
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
        for user in $(echo "$pwdfile" | grep "$shell" | cut -d: -f1);do
            get_expiry_date=$(/usr/bin/chage -l $user | grep 'Password expires' | cut -d: -f2)
            if [[ $get_expiry_date = ' never' || $get_expiry_date = 'never' ]];then
                printf "%-15s 永不过期\n" $user
                result="$result,$user:never"
            else
                password_expiry_date=$(date -d "$get_expiry_date" "+%s")
                current_date=$(date "+%s")
                diff=$(($password_expiry_date-$current_date))
                let DAYS=$(($diff/(60*60*24)))
                printf "%-15s %s天后过期\n" $user $DAYS
                result="$result,$user:$DAYS days"
            fi
        done
    done
    report_PasswordExpiry=$(echo $result | sed 's/^,//')
    echo ""
    echo "密码策略检查"
    echo "------------"
    grep -v "#" /etc/login.defs | grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_MIN_LEN|PASS_WARN_AGE"
}
function getSudoersStatus(){
    echo -e "\033[1;32m*******************************************************Sudoers检查*******************************************************\033[0m"
    conf=$(grep -v "^#" /etc/sudoers| grep -v "^Defaults" | sed '/^$/d')
    echo "$conf"
    echo ""
    #报表信息
    report_Sudoers="$(echo $conf | wc -l)"
}
function getProcessStatus(){
    echo -e "\033[1;32m*******************************************************进程检查*******************************************************\033[0m"
    if [ $(ps -ef | grep defunct | grep -v grep | wc -l) -ge 1 ];then
        echo ""
        echo "僵尸进程";
        echo "--------"
        ps -ef | head -n1
        ps -ef | grep defunct | grep -v grep
    fi
    echo ""
    echo "内存占用TOP10"
    echo "-------------"
    echo -e "PID %MEM RSS COMMAND
    $(ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10 )"| column -t 
    echo ""
    echo "CPU占用TOP10"
    echo "------------"
    top b -n1 | head -17 | tail -11
}
function getSyslogStatus(){
    echo -e "\033[1;32m*******************************************************syslog检查*******************************************************\033[0m"
    echo "服务状态：$(getState rsyslog)"
    echo ""
    echo "/etc/rsyslog.conf"
    echo "-----------------"
    cat /etc/rsyslog.conf 2>/dev/null | grep -v "^#" | grep -v "^\\$" | sed '/^$/d'  | column -t
}
function getFirewallStatus(){
    echo -e "\033[1;32m******************************************************* 防火墙检查*******************************************************\033[0m"
    #防火墙状态，策略等
    if [[ $centosVersion = 7 ]];then
        systemctl status firewalld >/dev/null  2>&1
        status=$?
        if [ $status -eq 0 ];then
                s="active"
        elif [ $status -eq 3 ];then
                s="inactive"
        elif [ $status -eq 4 ];then
                s="permission denied"
        else
                s="unknown"
        fi
    else
        s="$(getState iptables)"
    fi
    echo "firewalld: $s"
    echo ""
    echo "/etc/sysconfig/firewalld"
    echo "-----------------------"
    cat /etc/sysconfig/firewalld 2>/dev/null
}
function getState(){
    if [[ $centosVersion < 7 ]];then
        if [ -e "/etc/init.d/$1" ];then
            if [ `/etc/init.d/$1 status 2>/dev/null | grep -E "is running|正在运行" | wc -l` -ge 1 ];then
                r="active"
            else
                r="inactive"
            fi
        else
            r="unknown"
        fi
    else
        #CentOS 7+
        r="$(systemctl is-active $1 2>&1)"
    fi
    echo "$r"
}
function getSSHStatus(){
    echo -e "\033[1;32m*******************************************************SSH检查*******************************************************\033[0m"
    pwdfile="$(cat /etc/passwd)"
    echo "服务状态：$(getState sshd)"
    Protocol_Version=$(cat /etc/ssh/sshd_config | grep Protocol | awk '{print $2}')
    echo "SSH协议版本：$Protocol_Version"
    echo ""
    echo "信任主机"
    echo "--------"
    authorized=0
    for user in $(echo "$pwdfile" | grep /bin/bash | awk -F: '{print $1}');do
        authorize_file=$(echo "$pwdfile" | grep -w $user | awk -F: '{printf $6"/.ssh/authorized_keys"}')
        authorized_host=$(cat $authorize_file 2>/dev/null | awk '{print $3}' | tr '\n' ',' | sed 's/,$//')
        if [ ! -z $authorized_host ];then
            echo "$user 授权 \"$authorized_host\" 无密码访问"
        fi
        let authorized=authorized+$(cat $authorize_file 2>/dev/null | awk '{print $3}'|wc -l)
    done
    echo ""
    echo "是否允许ROOT远程登录"
    echo "--------------------"
    config=$(cat /etc/ssh/sshd_config | grep PermitRootLogin)
    firstChar=${config:0:1}
    if [ $firstChar == "#" ];then
        PermitRootLogin="yes" 
    else
        PermitRootLogin=$(echo $config | awk '{print $2}')
    fi
    echo "PermitRootLogin $PermitRootLogin"
    echo ""
    echo "/etc/ssh/sshd_config"
    echo "--------------------"
    cat /etc/ssh/sshd_config | grep -v "^#" | sed '/^$/d'
}
function jdk_check(){
    echo -e "\033[1;32m*******************************************************jdk检查*******************************************************\033[0m"
    java -version 2>/dev/null
    if [ $? -eq 0 ];then
	 echo $JAVA_HOME;
    fi
}
function getrpmlist(){
	#检查rpm包
    echo -e "\033[1;32m*******************************************************rpm包检查*******************************************************\033[0m"
    rpm -qa | grep -iE 'python|glibc'|sort
}
function checkNoticeServer(){
        #进行邮件服务器检查
        echo -e "\033[1;32m*******************************************************Eguan邮件服务器检查*******************************************************\033[0m"
    echo "tips：默认检测易观邮箱服务器！"
    
    for i in {25,465,587};
    do
    result=""
    nc -zv smtp.analysys.com.cn $i >/tmp/che.log 2>&1
    if [ `cat /tmp/che.log | grep -E "failed|timed out" | wc -l` -le 1 ];then
        result="True"
    else
        result="False"
    fi
    if [ $i = 25 ];then
        #echo "tips：默认检测易观邮箱服务器！"
        echo "邮件是否可以发出(port:$i):$result"
    else
        #echo "tips：默认检测易观邮箱服务器！"
        echo "邮件是否可以发出(SSL方式,port:$i):$result"
    fi
    done
}
function check(){
#    packget_update
    error_info
    version
    getSystemStatus-ok
    getCpuStatus-ok
    getMemStatus-ok
    getDiskStatus-ok，查看磁盘读写
    getServerBios-ok，查看硬件bios信息
    getNetworkStatus-ok，更多的是内网mysql/zk检查
    getListenStatus-ok，看端口12345、1234、1235、5678、5679 是否被占用
    getProcessStatus-ok，查看是否有僵尸进程
    getServiceStatus-ok, 查看开启的公共服务有哪些
    getAutoStartStatus-ok，查看启动服务有哪些
    getCronStatus-ok，查看计划任务有哪些
    getUserStatus-ok, 查看用户是否有特殊的
    getPasswordStatus-ok，检查密码策略
    getSudoersStatus-ok，查看超级管理用户
    getFirewallStatus-ok, 查看防火墙策略
    getSSHStatus-ok, 查看ssh状态
    getSyslogStatus-no, 没懂
    jdk_check-ok
    checkNoticeServer-no，邮箱检查不涉及
    getrpmlist-no, rpm包检查不涉及
    diskrwtest-ok, 磁盘检查
}
#执行检查并保存检查结果
check > $RESULTFILE
echo -e "\033[1;37m 通过以下命令查看结果：cat $RESULTFILE \033[0m"
