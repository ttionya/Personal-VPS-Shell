#!/bin/bash

# Version: 1.0.1
# Author: ttionya

################### Custom Setting ####################
# Zstandard 版本号
Latest_Zstandard_Ver="1.3.8"

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
    color yellow "===================== Zstandard 安装程序 启动 ===================="

    # Install Dependencies
    yum -y install gcc gcc-c++ make wget

    cd /usr/local/src
    if [ ! -s zstd-$Latest_Zstandard_Ver.tar.gz ]; then
        wget -c -t3 -T60 "https://github.com/facebook/zstd/releases/download/v$Latest_Zstandard_Ver/zstd-$Latest_Zstandard_Ver.tar.gz"
        if [ $? != 0 ]; then
            rm -rf zstd-$Latest_Zstandard_Ver.tar.gz
            color red "Zstandard 下载失败"
            exit 1
        fi
    fi

    # Make
    tar -zxvf zstd-$Latest_Zstandard_Ver.tar.gz
    cd zstd-$Latest_Zstandard_Ver
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        color red "Zstandard 编译失败"
        make clean
        exit 1
    fi

    # Copy
    cp -f ./zstd /usr/local/bin/

    # Alias
    Find_Alias_Zstandard=`grep -oE "^alias zstd(.*)$" /etc/profile`
    if [ -z $Find_Alias_Zstandard ]; then
        echo "" >> /etc/profile
        echo "alias unzstd='zstd -d'" >> /etc/profile
        echo "alias zstdcat='zstd -dc'" >> /etc/profile
        source /etc/profile
    fi

    # Clean
    cd ~
    rm -rf /usr/local/src/zstd-$Latest_Zstandard_Ver

    color green "===================== Zstandard $Latest_Zstandard_Ver 安装配置完成 ===================="
    color yellow "请重启终端以使 alias 生效"
}


# Show Install Information
clear
color blue "##########################################################"
color blue "# Auto Install Script for Facebook Zstandard             #"
color blue "# Author: ttionya                                        #"
color blue "##########################################################"
color ""
color yellow "将安装 Zstandard $Latest_Zstandard_Ver"
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
    color blue "Zstandard $Latest_Zstandard_Ver 安装被取消，未作任何更改..."
    color ""
fi

# Ver1.0.1
# - 修正文案无法正常显示的问题
