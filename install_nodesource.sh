#!/bin/bash

# Version: 1.0.0
# Author: ttionya
# https://github.com/nodesource/distributions


################### Custom Setting ####################
# Nodejs 大版本
Node_Ver="10"
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
################### Check Info End ####################


# Main Function
function main() {
    color ""
    color yellow "===================== Nodejs 安装程序 启动 ===================="

    # Install Node Source
    curl -sL https://rpm.nodesource.com/setup_${Node_Ver}.x | bash -

    # China
    if [[ ${In_China} == 1 ]]; then
        sed -i "s@^baseurl=.*\.com\/pub_${Node_Ver}\.x\/\(.*\)@baseurl=https://mirrors.tuna.tsinghua.edu.cn/nodesource/rpm_${Node_Ver}.x/\1@" /etc/yum.repos.d/nodesource-el7.repo
        color green "已将清华源作为 Node Source 源"
    fi

    # 安装
    yum clean all
    yum -y install nodejs

    # China
    if [[ ${In_China} == 1 ]]; then
        if [[ -f ~/.npmrc ]]; then
            Find_NPM_Registry=`grep -oE "^registry" ~/.npmrc`
            if [[ -n ${Find_NPM_Registry} ]]; then
                sed -i 's/^registry\(.*\)/# registry\1/' ~/.npmrc
            fi
        fi
        echo "registry=https://registry.npm.taobao.org/" >> ~/.npmrc
        color green "已将淘宝源作为 NPM 源"
    fi

    # Update NPM
    npm i -g npm

    color ""
    color green "===================== Nodejs 安装配置完成 ===================="
}


# Show Install Information
clear
color blue "##########################################################"
color blue "# Auto Install Script for Nodejs                         #"
color blue "# Author: ttionya                                        #"
color blue "##########################################################"
color ""
color yellow "将安装最新版 Nodejs"
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
    color blue "Nodejs 安装被取消，未作任何更改..."
    color ""
fi
