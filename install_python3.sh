#!/bin/bash

# Version: 1.0.2
# Author: ttionya


################### Custom Setting ####################
# Python 3 版本号
Latest_Python3_Ver="3.7.0"
# Python 3 安装路径
Install_Python3_Path="/usr/local/python3"

################### Check Info Start ####################
# Check root User
if [ $EUID != 0 ]; then
   echo "错误：该脚本必须以 root 身份运行"
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
    echo "错误：该脚本仅支持 CentOS 7.X 版本"
    exit 1
fi

# Check CPU Number
Cpu_Num=`cat /proc/cpuinfo | grep 'processor' | wc -l`
################### Check Info End ####################


# Main Function
function main() {
    echo ""
    echo "===================== Python 3 安装程序 启动 ===================="

    # Install Dependencies
    yum -y install gcc gcc-c++ libffi-devel sqlite-devel zlib zlib-devel

    cd /usr/local/src
    if [ ! -s Python-$Latest_Python3_Ver.tgz ]; then
        wget -c -t3 -T60 "https://npm.taobao.org/mirrors/python/$Latest_Python3_Ver/Python-$Latest_Python3_Ver.tgz" -O Python-$Latest_Python3_Ver.tgz
        if [ $? != 0 ]; then
            rm -rf Python-$Latest_Python3_Ver.tgz
            echo "Python 3 下载失败"
            exit 1
        fi
    fi

    # Configure && Make && Install
    tar -zxvf Python-$Latest_Python3_Ver.tgz
    cd Python-$Latest_Python3_Ver
    ./configure --prefix=$Install_Python3_Path
    if [ $? != 0 ]; then
        echo "Python 3 配置失败"
        exit 1
    fi
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        echo "Python 3 编译失败"
        make clean
        exit 1
    fi
    make install
    if [ $? != 0 ]; then
        echo "Python 3 安装失败"
        rm -rf $Install_Python3_Path
        exit 1
    fi

    echo "export PATH=\${PATH}:$Install_Python3_Path/bin" >> /etc/profile
    source /etc/profile

    echo "===================== Python $Latest_Python3_Ver 安装配置完成 ===================="
}


# Show Install Information
clear
echo "##########################################################"
echo "# Auto Install Script for Python 3                       #"
echo "# Author: ttionya                                        #"
echo "##########################################################"
echo ""
echo "将安装 Python $Latest_Python3_Ver"
echo ""
echo "是否安装？ (y/n)"
read -p "(Default: n):" Check_Install
if [ -z $Check_Install ]; then
    Check_Install="n"
fi

# Check Install
if [[ $Check_Install == y || $Check_Install == Y ]]; then
    main
else
    echo ""
    echo "Python $Latest_Python3_Ver 安装被取消，未作任何更改..."
    echo ""
fi

# Ver1.0.1
# - 将下载源更改为淘宝源
# - 添加依赖库
#
# Ver1.0.2
# - 添加 Python3.7 所需新依赖
# - 升级 Python3 版本