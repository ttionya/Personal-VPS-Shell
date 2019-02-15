#!/bin/bash

# Version: 1.2.0
# Author: ttionya
# https://docs.docker.com/install/linux/docker-ce/centos/


################### Custom Setting ####################
# Docker 用户，不存在会自动创建
Docker_User="docker"
# Docker Compose 版本
Docker_Compose_Ver="1.23.2"
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
    color yellow "==================== Docker CE 安装程序 启动 ===================="

    # Uninstall Old Version of Docker
    yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

    # Install Dependencies
    yum install -y yum-utils device-mapper-persistent-data lvm2

    # Set Docker CE Repo
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    # China
    if [[ ${In_China} == 1 ]]; then
        sed -i '1,/baseurl=\.*/{s@baseurl=\(.*\)@baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/$basearch/stable@}' /etc/yum.repos.d/docker-ce.repo
        sed -i '1,/gpgkey=\.*/{s@gpgkey=\(.*\)@gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg@}' /etc/yum.repos.d/docker-ce.repo
        color green "已将阿里巴巴源作为 Docker CE Repo 源"
    fi

    # Install Docker CE
    yum clean all
    yum makecache fast
    yum install -y docker-ce docker-ce-cli containerd.io

    # Create User And Group
    groupadd -f docker
    if id -u ${Docker_User} > /dev/null 2>&1; then
        if [[ `id -u ${Docker_User}` != 0 ]]; then
            usermod -aG docker ${Docker_User}
        fi
    else
        useradd -g docker -s /bin/bash ${Docker_User}
    fi

    # China
    if [[ ${In_China} == 1 ]]; then
        mkdir -p /etc/docker
        echo '{ "registry-mirrors": [ "https://registry.docker-cn.com" ] }' > /etc/docker/daemon.json
        color green "已将 Docker CN 源作为 Docker CE 镜像源"
    fi

    # Check Docker Compose
    check_docker_compose

    # Auto Run
    systemctl enable docker
    systemctl start docker

    color ""
    color green "==================== Docker CE 安装配置完成 ===================="
    color ""
    color yellow "如有问题，请重启系统"
}

# Check Docker Compose
function check_docker_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        if [[ `docker-compose --version | grep -oP '\d+(\.\d+)+'` == ${Docker_Compose_Ver} ]]; then
            color ""
            color yellow "已安装 Docker Compose ${Docker_Compose_Ver}，无须重新安装"
            color ""
        else
            install_docker_compose
        fi
    else
        install_docker_compose
    fi
}

# Install Docker Compose
function install_docker_compose() {
    if [[ ${In_China} == 1 ]]; then
        curl --retry 3 -L https://get.daocloud.io/docker/compose/releases/download/${Docker_Compose_Ver}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    else
        curl --retry 3 -L https://github.com/docker/compose/releases/download/${Docker_Compose_Ver}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    fi

    chmod +x /usr/local/bin/docker-compose
}


# Show Install Information
clear
color blue "##########################################################"
color blue "# Auto Install Script for Docker CE                      #"
color blue "# Author: ttionya                                        #"
color blue "##########################################################"
color ""
color yellow "将安装 Docker CE"
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
    color blue "Docker CE 安装被取消，未作任何更改..."
    color ""
fi

# Ver1.0.1
# - 自动添加 docker 组和用户
#
# Ver1.0.2
# - 支持设定服务器地址，设置为国内则自动将 Docker CE Repo 设置为阿里源，并使用国内 Docker 镜像
#
# Ver1.0.3
# - 防止设置源时出现目录未创建的问题
#
# Ver1.1.0
# - 增加安装 Docker Compose 功能
#
# Ver1.2.0
# - 更新 Docker CE 安装命令
# - 添加 Docker Compose 安装情况判断
# - 加速 Docker Compose 中国下载
# - 优化脚本
