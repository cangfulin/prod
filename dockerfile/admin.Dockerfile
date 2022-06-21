FROM <REG_ADDR>/<REG_SPACE>/<DOCKER_TYPE>:<BUILD_TAG>
RUN mv /etc/localtime /etc/localtime.old
RUN ln -s /usr/share/zoneinfo/Asia/Taipei /etc/localtime
#RUN ln -s /usr/share/zoneinfo/Etc/GMT+0  /etc/localtime
RUN echo "build: `date`" > /tmp/build.log
RUN mv /usr/share/nginx/html /usr/share/nginx/html.orig
COPY acctsystem /usr/share/nginx/html