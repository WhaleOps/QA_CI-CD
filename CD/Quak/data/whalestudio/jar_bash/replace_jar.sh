function tips(){

echo "******** 说明 ******** "
echo "1、此脚本作用只适用于：api-server、worker-server、master-server、alert-server lib下的jar包替换"



echo "******** 操作步骤 ******** "
echo "1、拷贝：将replace_jar.sh、新jar存放到 /data/tmp/目录下"
echo "2、修改：jar_old_file、jar_new_file、server、deploy_path 等内容"
echo "3、修改：若在 10.0.0.1执行，则修改：ip1='10.0.0.1'"
echo "4、执行：sh /data/tmp/replace_jar.sh "
echo "5、其他节点：重复执行步骤1-3"
echo "6、整体流程：旧jar备份、新jar替换、重启服务"
echo "******** 操作步骤 ******** "

}

function param_def(){
echo "****** 定义开始 *******"
echo "1、定制化内容"
main_path="/data/whalestudio/current/whalescheduler-1.0-SNAPSHOT-bin"

# 新旧jar、服务定义
server="master-server"
reg_jar_old="dolphinscheduler-master*"
jar_new_file="dolphinscheduler-master-cabb908-20230103.070756-1.jar"


echo "find $main_path/$server/libs -name \"$reg_jar_old\" | awk -F '/' '{print \$NF}'"
jar_old_file=`find $main_path/$server/libs -name "$reg_jar_old" | awk -F '/' '{print $NF}'`

echo "找到的旧jar: $jar_old_file"

deploy_path="sh /data/whalestudio/tool/deploy_QA.sh"

echo "2、固定内容"
ip1=`hostname -i`
current_time=`date +%m%d%H`

jar_bash=/data/whalestudio/jar_bash
jar_old_path=/data/whalestudio/jar_old/$current_time
jar_new_path=/data/whalestudio/jar_new


}

function scp_file(){
echo "****** 拷贝开始 *******"

echo "1、创建目录"
ssh $ip1 "mkdir -p $jar_bash"
ssh $ip1 "mkdir -p $jar_old_path"
ssh $ip1 "mkdir -p $jar_new_path"

echo "2、拷贝"
echo "scp /data/tmp/$jar_new_file $jar_new_path"

scp /data/tmp/$jar_new_file $jar_new_path


}

function jar_replace(){
echo "****** 替换开始 *******"

echo "1、旧jar 处理"
echo "ssh $ip1 mv $main_path/$server/libs/$jar_old_file $jar_old_path"
ssh $ip1 "mv $main_path/$server/libs/$jar_old_file $jar_old_path"

echo "2、新jar 处理"
echo "scp $jar_new_path/$jar_new_file $ip1:$main_path/$server/libs/"
scp $jar_new_path/$jar_new_file $ip1:$main_path/$server/libs/

echo "3、重启 $server"
echo "ssh $ip1 $deploy_path stop $server"
echo "ssh $ip1 $deploy_path start $server"
ssh $ip1 "$deploy_path stop $server"
ssh $ip1 "$deploy_path start $server"

echo "****** 替换结束 *******"

}

function res_cat(){
echo "****** 结果 *******"
echo "1、旧jar 查看"
echo "ssh $ip1 ls $jar_old_path/$jar_old_file"
ssh $ip1 "ls $jar_old_path/$jar_old_file"

echo "2、新jar 查看"
echo "ssh $ip1 ls $jar_new_path/$jar_new_file"
ssh $ip1 "ls $jar_new_path/$jar_new_file"

echo "3、新jar 安装目录看"
echo "ssh $ip1 ls $main_path/$server/libs/$jar_new_file"
ssh $ip1 "ls $main_path/$server/libs/$jar_new_file"

}


function main(){
    tips
    param_def
    scp_file
    jar_replace
    res_cat

}

main