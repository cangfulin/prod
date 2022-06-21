FROM <REG_ADDR>/<REG_SPACE>/<DOCKER_TYPE>:<BUILD_TAG>
RUN  rm -rf /home/gameserver     \
&&  mv /etc/localtime /etc/localtime.old \
&& ln -s /usr/share/zoneinfo/Asia/Taipei  /etc/localtime
#&& ln -s /usr/share/zoneinfo/Etc/GMT+0  /etc/localtime
#COPY . /home/gameserver/gameserver
COPY Server-FishGameServer /home/gameserver
RUN chmod 755 /home/gameserver/start.sh &&  yum clean all
COPY Server-FishGameServer/config/development/mysql/mysql_log_rw.json /home/gameserver/config/development/mysql/mysql_log_rw.json
