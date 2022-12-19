#! /bin/sh

source /etc/profile
deploy=/data/whalestudio/tool/deploy_QA.sh




defend(){
PRO_NAME=$1
#少于4，重启进程
NUM=`ps aux | grep $PRO_NAME | grep -v grep |wc -l`
echo "当前服务是: $PRO_NAME"
echo "服务数量是: $NUM"
if [ "$NUM" -lt "4" ];then
         echo "$PRO_NAME was killed"
         sh $deploy start $PRO_NAME
         echo "启动成功"

#大于4，杀掉所有进程，重启
elif [ "$NUM" -gt "4" ];then
echo "more than 1 $PRO_NAME,killall $PRO_NAME"
ps -ef|grep $PRO_NAME|grep -v grep|awk '{print "kill -9 " $2}' |sh
sh $deploy start $PRO_NAME
echo "启动成功"
fi
}


defend $1

