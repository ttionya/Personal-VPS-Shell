#!/bin/bash

# Version: 1.0.0
# Author: ttionya


################### Custom Setting ####################
# GoAccess 版本号
Latest_GoAccess_Ver="1.3"
# GoAccess 安装路径
Install_GoAccess_Path="/usr/local/goaccess"
# 中国服务器
In_China=0

################### Function ####################
function color() {
    case $1 in
        red)
            echo -e "\033[31m$2\033[0m"
            ;;
        green)
            echo -e "\033[32m$2\033[0m"
            ;;
        yellow)
            echo -e "\033[33m$2\033[0m"
            ;;
        blue)
            echo -e "\033[34m$2\033[0m"
            ;;
        *)
            echo $2
    esac
}

################### Check Info Start ####################
# Check root User
if [ $EUID != 0 ]; then
   color red "错误：该脚本必须以 root 身份运行"
   exit 1
fi

# Check CentOS Version
# CentOS 7.X Only
if [ -s /etc/redhat-release ]; then
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/redhat-release`
else
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/issue`
fi
CentOS_Ver=${CentOS_Ver%%.*}
if [ $CentOS_Ver != 7 ]; then
    color red "错误：该脚本仅支持 CentOS 7.X 版本"
    exit 1
fi

# Check CPU Number
Cpu_Num=`cat /proc/cpuinfo | grep 'processor' | wc -l`
################### Check Info End ####################


# Main Function
function main() {
    color ""
    color yellow "===================== GoAccess 安装程序 启动 ===================="

    # Install EPEL Repo
    curl https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/repo_epel.sh | bash -s -- $In_China

    # Install Dependencies
    yum -y install autoconf gcc gcc-c++ libmaxminddb-devel make ncurses-devel openssl-devel tokyocabinet-devel wget

    cd /usr/local/src
    if [ ! -s goaccess-$Latest_GoAccess_Ver.tar.gz ]; then
        wget -c -t3 -T60 "https://github.com/allinurl/goaccess/archive/v$Latest_GoAccess_Ver.tar.gz" -O goaccess-$Latest_GoAccess_Ver.tar.gz
        if [ $? != 0 ]; then
            rm -rf goaccess-$Latest_GoAccess_Ver.tar.gz
            color red "GoAccess 下载失败"
            exit 1
        fi
    fi

    # Configure && Make && Install
    tar -zxvf goaccess-$Latest_GoAccess_Ver.tar.gz
    cd goaccess-$Latest_GoAccess_Ver
    ./configure --prefix=$Install_GoAccess_Path --enable-utf8 --enable-geoip=mmdb --enable-tcb=btree --with-openssl
    if [ $? != 0 ]; then
        color red "GoAccess 配置失败"
        exit 1
    fi
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        color red "GoAccess 编译失败"
        make clean
        exit 1
    fi
    make install
    if [ $? != 0 ]; then
        color red "GoAccess 安装失败"
        rm -rf $Install_GoAccess_Path
        exit 1
    fi

    ln -sf $Install_GoAccess_Path/bin/goaccess /usr/local/bin/

    # Clean Up
    cd ~
    rm -rf /usr/local/src/goaccess-$Latest_GoAccess_Ver/
    color green "===================== GoAccess 安装完成，开始下载 GeoIP 数据库 ===================="

    # Download GeoIP2 Database
    cd $Install_GoAccess_Path/etc/goaccess/
    rm -rf GeoLite2-City.mmdb GeoLite2-City.mmdb.gz
    wget -c -t3 -T60 "http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz"
    if [ $? != 0 ]; then
        rm -rf GeoLite2-City.mmdb.gz
        color red "GoAccess GeoIP Database 下载失败"
        exit 1
    fi
    gunzip GeoLite2-City.mmdb.gz
    if [ $? != 0 ]; then
        rm -rf GeoLite2-City.mmdb.gz
        color red "GoAccess GeoIP Database 解压失败"
        exit 1
    fi

    color ""
    color green "===================== GoAccess $Latest_GoAccess_Ver 安装配置完成 ===================="
}


# Show Install Information
clear
color blue "##########################################################"
color blue "# Auto Install Script for GoAccess                       #"
color blue "# Author: ttionya                                        #"
color blue "##########################################################"
color ""
color yellow "将安装 GoAccess $Latest_GoAccess_Ver"
color ""
color x "是否安装？ (y/n)"
read -p "(Default: n):" Check_Install
if [ -z $Check_Install ]; then
    Check_Install="n"
fi

# Check Install
if [[ $Check_Install == y || $Check_Install == Y ]]; then
    main
else
    color ""
    color blue "GoAccess $Latest_GoAccess_Ver 安装被取消，未作任何更改..."
    color ""
fi

# 自定义日志格式
# https://goaccess.io/man#custom-log

# 使用方法
# goaccess -p /path/to/goaccess.conf -f /path/to/nginx.log -a -o /path/to/report.html
