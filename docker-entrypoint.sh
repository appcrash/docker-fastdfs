#!/bin/bash

monitor() {
    if ! ps ax | grep -v grep | grep $1 > /dev/null; then
        echo "process $1 isn't running, exit"
        exit 1;
    fi
}

expand_server_list() {
    server_list=""

    for ip in $(echo $1 | sed "s#,# #g"); do
        server_list+="tracker_server=$ip\n"
    done

    echo "server list is $server_list"
}

replace_line() {
    local file=$1
    local key=$2
    local value=$3

    # special case for tracker_server, it can be set multiple times
    # so env variable use format like key=ip1:port1,ip2:port2,...
    case $key in
        "tracker_server" )
        expand_server_list $value

        echo "overriding server_list to $server_list"
        sed -i -e "s#^tracker_server=.*#$server_list#g" $file
        return
    esac

    echo "overriding $key=$value in $file"
    sed -i -e "s#^$key[^=]*=.*#$key=$value#g" $file
}

replace_config_in_file() {
    local conf_file=$1
    local prefix=$2


    # config any item in tracker.conf or storage.conf
    # by set env variable like $PREFIX_some_key=some_value
    all_env=`env|grep ^$prefix`
    echo "$conf_file with $prefix env:"
    echo $all_env
    for line in $all_env; do
        key=${line%=*}
        value=${line##*=}
        key_striped=${key##${prefix}}
        if [[ -z $key || -z $value ]]; then
            continue
        fi

        replace_line $conf_file $key_striped $value
    done 
    
}

replace_config_nginx_file() {
    local conf_file=$1
    local prefix=$2

    all_env=`env|grep ^$prefix`
    echo "$conf_file with $prefix env:"
    echo $all_env
    for line in $all_env; do
        key=${line%=*}
        value=${line##*=}
        key_striped=${key##${prefix}}
        if [[ -z $key || -z $value ]]; then
            continue
        fi

        echo "changing placeholder $key_striped to $value in $conf_file"
        sed -i -e "s#$key_striped#$value#g" $conf_file
    done <<< $all_env
}

# rename all sample to .conf
for f in /etc/fdfs/*; do
    case "$f" in
        *.sample) mv $f ${f%.*}; 
    esac
done



case "$SERVER_TYPE" in
    "tracker" )
    echo "server is tracker"

    replace_config_in_file /etc/fdfs/tracker.conf TRACKER_
    /etc/init.d/fdfs_trackerd start;
    while true; do
        monitor fdfs_trackerd;
        sleep 10;
    done
    ;;

    "storage" )
    echo "server is storage"

    replace_config_in_file /etc/fdfs/storage.conf STORAGE_
    replace_config_in_file /etc/fdfs/mod_fastdfs.conf MOD_
    replace_config_nginx_file /usr/local/nginx/conf/nginx.conf NG_

    /etc/init.d/fdfs_storaged start;
    /usr/local/nginx/sbin/nginx;

    while true; do
        monitor fdfs_storaged
        monitor nginx
        sleep 10
    done
    ;;
esac






