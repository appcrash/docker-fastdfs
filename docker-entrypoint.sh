#!/bin/bash

BASE_DIR=/var/fastdfs


set_tracker_conf() {
    TRACKER_DIR=$BASE_DIR/trackerd
    if [ ! -d $TRACKER_DIR ]; then
        mkdir -p $TRACKER_DIR
    fi

    sed -i -e "s#^base_path=.*#base_path=$TRACKER_DIR#g" /etc/fdfs/tracker.conf
}

# tracker_server_ip_and_port
set_storage_conf() {
    STORED_DIR=$BASE_DIR/stored
    STORE_DATA_DIR=$BASE_DIR/data_store0

    # config storaged
    sed -i -e "s#^base_path=.*#base_path=$STORED_DIR#g" /etc/fdfs/storage.conf
    sed -i -e "s#^store_path0=.*#store_path0=$STORE_DATA_DIR#g" /etc/fdfs/storage.conf
    sed -i -e "s#^tracker_server=.*#tracker_server=$1#g" /etc/fdfs/storage.conf

    # config nginx
    sed -i -e "s#^store_path0.*#store_path0=$STORE_DATA_DIR#g" /etc/fdfs/mod_fastdfs.conf
    sed -i -e "s#^tracker_server=.*#tracker_server=$1#g" /etc/fdfs/mod_fastdfs.conf
    sed -i -e "s#^url_have_group_name.*#url_have_group_name=true#g" /etc/fdfs/mod_fastdfs.conf

    sed -i -e "s#FASTDFS_STORAGE_ROOT#$STORE_DATA_DIR/data#g" /usr/local/nginx/conf/nginx.conf
}

monitor() {
    if ! ps ax | grep -v grep | grep $1 > /dev/null; then
        echo "process $1 isn't running, exit"
        exit 1;
    fi
}

# rename all sample to .conf
for f in /etc/fdfs/*; do
    case "$f" in
        *.sample) mv $f ${f%.*}; 
    esac
done



if [ ! -z "$TRACKER_SERVER" ]; then
    echo "creating tracker server ..."
    set_tracker_conf;
    /etc/init.d/fdfs_trackerd start;

    while true; do
        monitor fdfs_trackerd;
        sleep 10;
    done
elif [ ! -z "$STORAGE_SERVER" ]; then
    if [ -z "$TRACKER_IP" ]; then
        echo "must set tracker ip for storage server" && exit 1;
    fi

    echo "creating storage server ..."
    set_storage_conf $TRACKER_IP:22122;
    /etc/init.d/fdfs_storaged start;
    /usr/local/nginx/sbin/nginx;


    while true; do
        monitor fdfs_storaged
        monitor nginx
        sleep 10
    done
else
    echo 'need to specify server type' && exit 1;
fi

        

#exec /bin/bash
