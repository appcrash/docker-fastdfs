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
    STORE_DATA_DIR=$BASE_DIR/store0
    sed -i -e "s#^base_path=.*#base_path=$STORED_DIR#g" /etc/fdfs/storage.conf
    sed -i -e "s#^store_path0=.*#store_path0=$STORE_DATA_DIR#g" /etc/fdfs/storage.conf
    sed -i -e "s#^tracker_server=.*#tracker_server=$1#g" /etc/fdfs/storage.conf
}


for f in /etc/fdfs/*; do
    case "$f" in
        *.sample) mv $f ${f%.*}; 
    esac
done

set_tracker_conf;
#set_storage_conf

        

exec /bin/bash
