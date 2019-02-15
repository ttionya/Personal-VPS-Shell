#!/bin/bash

# Version: 1.1.0
# Author: ttionya


################### Custom Setting ####################
# Git 版本号
Latest_Git_Ver="2.20.1"
# Git 安装路径
Install_Git_Path="/usr/local/git"

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
if [[ ${EUID} != 0 ]]; then
   color red "错误：该脚本必须以 root 身份运行"
   exit 1
fi

# Check CentOS Version
# CentOS 7.X Only
if [[ -s /etc/redhat-release ]]; then
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/redhat-release`
else
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/issue`
fi
CentOS_Ver=${CentOS_Ver%%.*}
if [[ ${CentOS_Ver} != 7 ]]; then
    color red "错误：该脚本仅支持 CentOS 7.X 版本"
    exit 1
fi

# Check CPU Number
Cpu_Num=`cat /proc/cpuinfo | grep 'processor' | wc -l`
################### Check Info End ####################


# Main Function
function main() {
    color ""
    color yellow "===================== Git 安装程序 启动 ===================="

    # Install Dependencies
    yum -y install autoconf curl-devel expat-devel gettext-devel gcc gcc-c++ perl-ExtUtils-MakeMaker zlib zlib-devel

    cd /usr/local/src
    if [[ ! -s git-v${Latest_Git_Ver}.tar.gz ]]; then
        wget -c -t3 -T60 "https://github.com/git/git/archive/v${Latest_Git_Ver}.tar.gz" -O git-v${Latest_Git_Ver}.tar.gz
        if [[ $? != 0 ]]; then
            color red "错误：Git 下载失败"
            rm -rf git-v${Latest_Git_Ver}.tar.gz
            exit 1
        fi
    fi

    # Configure && Make && Install
    tar -zxvf git-v${Latest_Git_Ver}.tar.gz
    cd git-${Latest_Git_Ver}
    make configure
    ./configure --prefix=${Install_Git_Path}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：Git 配置失败"
        exit 1
    fi
    make all -j ${Cpu_Num}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：Git 编译失败"
        make clean
        exit 1
    fi
    make install
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：Git 安装失败"
        rm -rf ${Install_Git_Path}
        exit 1
    fi

    ln -sf ${Install_Git_Path}/bin/git /usr/local/bin/

    # Clean Up
    cd ~
    rm -rf /usr/local/src/git-${Latest_Git_Ver}/

    color ""
    color green "===================== Git ${Latest_Git_Ver} 安装配置完成 ===================="
}


# Show Install Information
clear
color blue "##########################################################"
color blue "# Auto Install Script for Git                            #"
color blue "# Author: ttionya                                        #"
color blue "##########################################################"
color ""
color yellow "将安装 Git ${Latest_Git_Ver}"
color ""
color x "是否安装？ (y/n)"
read -p "(Default: n):" Check_Install
if [[ -z ${Check_Install} ]]; then
    Check_Install="n"
fi

# Check Install
if [[ ${Check_Install} == y || ${Check_Install} == Y ]]; then
    main
else
    color ""
    color blue "Git ${Latest_Git_Ver} 安装被取消，未作任何更改..."
    color ""
fi

# Ver1.0.1
# - 添加遗漏的依赖项
#
# Ver1.1.0
# - 更新 Git 安装版本
# - 美化安装界面
# - 优化脚本
