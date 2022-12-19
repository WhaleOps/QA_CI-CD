#! /bin/sh

source /etc/profile
PRO_NAME=alert-server
deploy=/data/whalestudio/tool/deploy_QA.sh
NUM=`ps aux | grep -w ${PRO_NAME} | grep -v grep |wc -l`




     #少于2，重启进程
     if [ "${NUM}" -lt "2" ];then
         echo "${PRO_NAME} was killed aaaaaaaa"
         sh $deploy start ${PRO_NAME}
         echo "启动成功"

     #大于2，杀掉所有进程，重启
     elif [ "${NUM}" -gt "2" ];then
         echo "more than 1 ${PRO_NAME},killall ${PRO_NAME}"
         killall -9 $PRO_NAME
         sh $deploy start ${PRO_NAME}
         echo "启动成功"
     fi

    sleep 5s