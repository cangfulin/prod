#!/bin/bash
set -e

table_name=("game_revenue_agent" "game_revenue_hall" "game_revenue_player" "user_revenue_agent" "user_revenue_hall" "user_revenue_player")

if [ ${DEPLOY_TARGET} == "IG_QA" ] 
then
    for ((i=0; i < ${#table_name[@]}; i++))
        do
            sh k8s/jenkins/${SUBDIR}/${JOB_NAME}/delete_data.sh 10.0.5.238 3307 wagers_1 ${table_name[$i]} AccountDate
        done
    sh k8s/jenkins/${SUBDIR}/${JOB_NAME}/delete_data.sh 10.0.5.238 3307 wagers_1 wagers_bet CreateTime
    echo 已刪除 ${date=`date -d "-90 day" +"%Y"-"%m"-"%d"`} 前資料
fi

if [ ${DEPLOY_TARGET} == "IG_Server" ] 
then
    for ((i=0; i < ${#table_name[@]}; i++))
        do
            sh k8s/jenkins/${SUBDIR}/${JOB_NAME}/delete_data.sh 10.0.5.230 3308 wagers_1 ${table_name[$i]} AccountDate
        done
    sh k8s/jenkins/${SUBDIR}/${JOB_NAME}/delete_data.sh 10.0.5.230 3308 wagers_1 wagers_bet CreateTime
    echo 已刪除 ${date=`date -d "-90 day" +"%Y"-"%m"-"%d"`} 前資料
fi

if [ ${DEPLOY_TARGET} == "IG_Game" ] 
then
    for ((i=0; i < ${#table_name[@]}; i++))
        do
            sh k8s/jenkins/${SUBDIR}/${JOB_NAME}/delete_data.sh 10.0.5.238 3306 wagers_1 ${table_name[$i]} AccountDate
        done
    sh k8s/jenkins/${SUBDIR}/${JOB_NAME}/delete_data.sh 10.0.5.238 3306 wagers_1 wagers_bet CreateTime
    echo 已刪除 ${date=`date -d "-90 day" +"%Y"-"%m"-"%d"`} 前資料
fi
