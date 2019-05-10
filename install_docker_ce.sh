#!/usr/bin/env bash

# Version: 2.0.0
# Author: ttionya
# https://docs.docker.com/install/linux/docker-ce/centos/
# https://github.com/docker/compose/releases


################### Custom Setting ####################
# Docker Compose 版本
DOCKER_COMPOSE_VERSION="1.24.0"
# 中国服务器
CHINA_SERVER=0


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

# Check System Information
function check_system_info() {
    # Check root User
    if [[ ${EUID} != 0 ]]; then
        color red "错误：该脚本必须以 root 身份运行"
        exit 1
    fi

    # Check CentOS Version
    # CentOS 7.X Only
    if [[ -s /etc/redhat-release ]]; then
        SYSTEM_VERSION="$(grep -oE "[0-9.]+" /etc/redhat-release)"
    else
        SYSTEM_VERSION="$(grep -oE "[0-9.]+" /etc/issue)"
    fi
    SYSTEM_VERSION=${SYSTEM_VERSION%%.*}
    if [[ ${SYSTEM_VERSION} != 7 ]]; then
        color red "错误：该脚本仅支持 CentOS 7.X 版本"
        exit 1
    fi
}

# Install Docker CE Repo
function install_docker_ce_repo() {
    yum -y install yum-utils

    # Set Docker CE Repo
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    if [[ $? != 0 ]]; then
        color ""
        color red "Docker CE Repo 安装失败"
        exit 1
    fi

    # China Server
    if [[ ${CHINA_SERVER} == 1 ]]; then
        sed -i '1,/baseurl=\.*/{s@baseurl=\(.*\)@baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/$basearch/stable@}' /etc/yum.repos.d/docker-ce.repo
        sed -i '1,/gpgkey=\.*/{s@gpgkey=\(.*\)@gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg@}' /etc/yum.repos.d/docker-ce.repo
        color green "已设置阿里巴巴源作为 Docker CE Repo 镜像源"
    fi

    # Result
    color ""
    color green "===================== Docker CE Repo 安装完成 ====================="
    color ""
}

# Check Docker CE Repo
function check_docker_ce_repo() {
    color ""

    yum clean all
    yum makecache fast

    IS_INSTALLED_DOCKER_CE_REPO=$(yum list | grep -c docker-ce-stable)

    if [[ ${IS_INSTALLED_DOCKER_CE_REPO} != 0 ]]; then
        color yellow "重新安装 Docker CE Repo？ (y/n)"
        read -p "(Default: n):" CHECK_REINSTALL_REPO

        # Check Reinstall
        if [[ $(echo ${CHECK_REINSTALL_REPO:-n} | tr [a-z] [A-Z]) == Y ]]; then
            NEED_INSTALL_REPO=1
        else
            NEED_INSTALL_REPO=0
        fi
    else
        NEED_INSTALL_REPO=1
    fi

    if [[ ${NEED_INSTALL_REPO} == 1 ]]; then
        install_docker_ce_repo
    else
        color ""
        color yellow "跳过 Docker CE Repo 安装..."
    fi
}

# Remove Old Version of Docker
function remove_old_docker() {
    yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
}

# Install Dependencies
function install_dependencies() {
    yum install -y device-mapper-persistent-data lvm2
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：依赖安装失败"
        exit 1
    fi
}

# Install Docker CE
function install_docker_ce() {
    color ""

    yum clean all
    yum makecache fast

    yum install -y docker-ce docker-ce-cli containerd.io
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：Docker CE 安装失败"
        exit 1
    fi

    # Result
    color ""
    color green "===================== Docker CE 安装完成 ====================="
    color ""
}

# Configure Docker CE
function configure_docker_ce() {
    mkdir -p /etc/docker

    # China Server
    if [[ ${CHINA_SERVER} == 1 ]]; then
        FILE_CONF_DAEMON="/etc/docker/daemon.json"

        if [[ -f ${FILE_CONF_DAEMON} ]]; then
            color yellow "${FILE_CONF_DAEMON} 已存在，跳过镜像源设置"
        else
            echo '{ "registry-mirrors": [ "https://registry.docker-cn.com" ] }' > ${FILE_CONF_DAEMON}
            color green "已设置 Docker CN 源作为 Docker CE 镜像源"
        fi
    fi

    # Auto Run
    systemctl enable docker.service
    systemctl restart docker.service

    # Result
    color ""
    color green "==================== Docker CE 配置完成 ===================="
    color ""
}

# Install Docker Compose
function install_docker_compose() {
    BIN_DOCKER_COMPOSE="/usr/local/bin/docker-compose"

    if [[ ${CHINA_SERVER} == 1 ]]; then
        wget -c -t3 -T60 "https://get.daocloud.io/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -O ${BIN_DOCKER_COMPOSE}
    else
        wget -c -t3 -T60 "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -O ${BIN_DOCKER_COMPOSE}
    fi
    if [[ $? != 0 ]]; then
        rm -rf ${BIN_DOCKER_COMPOSE}
        color ""
        color red "错误：Docker Compose 下载失败"
        exit 1
    fi

    chmod +x ${BIN_DOCKER_COMPOSE}
}

# Check Docker Compose
function check_docker_compose() {
    color ""
    BIN_DOCKER_COMPOSE="/usr/local/bin/docker-compose"

    if which ${BIN_DOCKER_COMPOSE} > /dev/null 2>&1; then
        if [[ $(${BIN_DOCKER_COMPOSE} --version | grep -oP '\d+(\.\d+)+') == ${DOCKER_COMPOSE_VERSION} ]]; then
            color ""
            color yellow "已安装 Docker Compose ${DOCKER_COMPOSE_VERSION}，无须重新安装"

            NEED_INSTALL_DOCKER_COMPOSE=0
        else
            NEED_INSTALL_DOCKER_COMPOSE=1
        fi
    else
        NEED_INSTALL_DOCKER_COMPOSE=1
    fi

    if [[ ${NEED_INSTALL_DOCKER_COMPOSE} == 1 ]]; then
        install_docker_compose
    else
        color ""
        color yellow "跳过 Docker Compose 安装..."
    fi
}

# Main
function main() {
    color ""
    color blue "===================== Docker CE 安装程序 启动 ====================="

    remove_old_docker
    install_dependencies

    install_docker_ce
    configure_docker_ce

    check_docker_compose

    color ""
    color green "===================== Docker CE 安装程序已完成 ====================="
    color ""
}


################### Start ####################
check_system_info
check_docker_ce_repo

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
read -p "(Default: n):" CHECK_INSTALL

# Check Install
if [[ $(echo ${CHECK_INSTALL:-n} | tr [a-z] [A-Z]) == Y ]]; then
    main
else
    color ""
    color blue "Docker CE 安装被取消..."
fi
################### End ####################

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
#
# Ver2.0.0
# - 优化变量命名方式
# - 拆分流程到函数中
# - 用询问替代强制重新安装依赖
# - 优化脚本
# - 更新 Docker Compose 版本
