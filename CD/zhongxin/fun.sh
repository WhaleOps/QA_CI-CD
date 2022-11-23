#!/bin/bash



get_current_day(){
    day=$1
    if [ $day == "today" ]
    then
        today=`date +%m%d`
        echo "今日日期："$today
        echo $today
    elif [ $day == "recent_day" ]
    then
        today=`ls -Art |grep ^[0-9].*[0-9]$ | tail -n 1`
        echo "最近日期："$today
        $today
    else
        echo "非法日期"
    fi
}

aaa=$(get_current_day "today")
echo "返回值："$aaa