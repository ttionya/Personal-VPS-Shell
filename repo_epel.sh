#!/bin/bash

# Version: 1.0.0
# Author: ttionya


################### Customer Setting ####################
# 中国服务器
In_China=0
if [[ $1 == 1 ]]; then
    In_China=1
fi

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
################### Check Info End ####################

# Install EPEL Repo Function
function install_epel() {
    color ""
    color yellow "==================== 开始安装 EPEL Repo ===================="

    yum -y install epel-release
    if [ $? != 0 ]; then
        color red "错误：EPEL 安装失败"
        exit 1
    fi

    # China
    if [[ $In_China == 1 ]]; then
        sed -i 's@^\(#\)\?baseurl=.*\.org\/pub\/epel\/\(.*\)@baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/\2@' /etc/yum.repos.d/epel.repo
        color green "已将清华源作为 EPEL 源"
    fi

    color ""
    color green "==================== EPEL Repo 安装完成 ===================="
}

# Check EPEL
Is_Installed_EPEL=`yum list installed | grep epel-release | wc -l`

if [[ $Is_Installed_EPEL == 1 ]]; then
    color yellow "检测到已安装 EPEL Repo，跳过..."
else
    color yellow "检测到未安装 EPEL Repo，即将安装..."
    install_epel
fi
