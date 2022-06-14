MASTER_DB_USER='root'
MASTER_DB_PASSWD='This123kw'
MASTER_DB_HOST=$1
MASTER_DB_PORT=$2
  
data_name=$3
table_name=$4
add_datatime=$5
DEL_TIME=`date -d "-90 day" +"%y"-"%m"-"%d"`
del_sql="delete FROM $data_name.$table_name  WHERE $add_datatime  <= '$DEL_TIME';"
  
mysql -u$MASTER_DB_USER -p$MASTER_DB_PASSWD -h $MASTER_DB_HOST -P $MASTER_DB_PORT -e "${del_sql}"
