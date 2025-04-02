#!/bin/bash
# Description: v2rayN software proxy, default 10808 port is socks proxy, 10809 port is http/https proxy.

HOST='10.10.100.100:10809'

function start(){
        echo "[INFO] start http proxy......"
        export HTTP_PROXY="$HOST"
        export HTTPS_PROXY="$HOST"

        sed -i '/HTTP.*PROXY/d' ~/.bashrc
        echo 'export HTTP_PROXY="'$HOST'"' >> ~/.bashrc
        echo 'export HTTPS_PROXY="'$HOST'"' >> ~/.bashrc

        echo "HTTP_PROXY: $HTTP_PROXY" "HTTPS_PROXY: $HTTPS_PROXY"
        curl -s https://cip.cc
}

function stop(){
        echo "[INFO] stop http proxy......"
        unset HTTPS_PROXY HTTP_PROXY

        sed -i '/HTTP.*PROXY/d' ~/.bashrc
        echo "HTTP_PROXY: $HTTP_PROXY" "HTTPS_PROXY: $HTTPS_PROXY"
        curl -s https://cip.cc
}

function status(){
        if [ "$HTTP_PROXY" -a "$HTTPS_PROXY" ]; then
                echo "[INFO] http proxy is running......"
        else
                echo "[INFO] http proxy is stop......"
        fi
        echo "HTTP_PROXY: $HTTP_PROXY" "HTTPS_PROXY: $HTTPS_PROXY"
        curl -s https://cip.cc
}

case $1 in
        start)
                start;;
        stop)
                stop;;
        status)
                status;;
        *)
                echo "Usage: source $0 [ start | stop | status ]"
esac
