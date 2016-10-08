FROM centos

ENV NGINX_VERSION 1.10.1

RUN yum -y install gcc gcc-c++ cmake automake autoconf libtool make pcre-devel zlib-devel openssl-devel

RUN mkdir -p /home/build

WORKDIR /home/build

RUN curl -sSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz | tar -xvz   &&  \
    curl -sSL https://github.com/happyfish100/libfastcommon/archive/master.tar.gz | tar -xvz && \
    curl -sSL https://github.com/happyfish100/fastdfs/archive/master.tar.gz | tar -xvz && \
    curl -sSL https://github.com/happyfish100/fastdfs-nginx-module/archive/master.tar.gz | tar -xvz 

RUN cd libfastcommon-master && \
    ./make.sh && \
    ./make.sh install

RUN cd fastdfs-master && \
    ./make.sh && \
    ./make.sh install && \
    cp conf/http.conf conf/mime.types /etc/fdfs

RUN cd nginx-$NGINX_VERSION && \
    ./configure --with-http_ssl_module --add-module=../fastdfs-nginx-module-master/src && \
    make -j4 && \
    make install && \
    cp ../fastdfs-nginx-module-master/src/mod_fastdfs.conf /etc/fdfs/

RUN rm -rf /home/build

COPY nginx.conf /usr/local/nginx/conf/
COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat

ENTRYPOINT ["docker-entrypoint.sh"]

