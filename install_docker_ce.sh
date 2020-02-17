#!/usr/bin/env bash
#
# For install Docker (Community Edition) and Docker Compose with Docker CE RPM repository.
#
# Version: 2.1.0
# Author: ttionya
#
# Usage:
#     sh upgrade_kernel.sh
#
# https://docs.docker.com/install/linux/docker-ce/centos/
# https://github.com/docker/compose/releases


#################### Custom Setting ####################
# 日志打印时区（留空使用服务器时区）
LOG_TIMEZONE=""
# Docker Compose Version
DOCKER_COMPOSE_VERSION="1.25.4"
# 中国服务器
CHINA_SERVER="FALSE"


#################### Function ####################
########################################
# Print colorful message.
# Arguments:
#     color
#     message
# Outputs:
#     Colorful message
########################################
function color() {
    case $1 in
        red)     echo -e "\033[31m$2\033[0m" ;;
        green)   echo -e "\033[32m$2\033[0m" ;;
        yellow)  echo -e "\033[33m$2\033[0m" ;;
        blue)    echo -e "\033[34m$2\033[0m" ;;
        none)    echo $2 ;;
    esac
}

########################################
# Print error message (red).
# Arguments:
#     message
# Outputs:
#     Error message
########################################
function error() {
    color red "[$(TZ="${LOG_TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1" >&2
}

########################################
# Print success message (green).
# Arguments:
#     message
# Outputs:
#     Success message
########################################
function success() {
    color green "[$(TZ="${LOG_TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1"
}

########################################
# Print warning message (yellow).
# Arguments:
#     message
# Outputs:
#     Warn message
########################################
function warn() {
    color yellow "[$(TZ="${LOG_TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1"
}

########################################
# Print information message (blue).
# Arguments:
#     message
# Outputs:
#     Information message
########################################
function info() {
    color blue "[$(TZ="${LOG_TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1"
}

# Check System Information
function check_system_info() {
    # Check root User
    if [[ "${EUID}" != "0" ]]; then
        error "该脚本必须以 root 身份运行"
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
    if [[ "${SYSTEM_VERSION}" != "7" ]]; then
        error "该脚本仅支持 CentOS 7.X 版本"
        exit 1
    fi
}

# Install Docker CE Repository
function install_docker_ce_repository() {
    color none ""
    color blue "==================== 开始安装 Docker CE RPM Repository ===================="

    yum -y install yum-utils

    # Set Docker CE Repository
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    if [[ $? -ne 0 ]]; then
        error "Docker CE repository 安装失败"
        exit 1
    fi

    # China Server
    if [[ "${CHINA_SERVER}" == "TRUE" ]]; then
        sed -i '1,/baseurl=\.*/{s@baseurl=\(.*\)@baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/$basearch/stable@}' /etc/yum.repos.d/docker-ce.repo
        sed -i '1,/gpgkey=\.*/{s@gpgkey=\(.*\)@gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg@}' /etc/yum.repos.d/docker-ce.repo
        success "已设置阿里巴巴源作为 Docker CE RPM repository 镜像源"
    fi

    # Result
    color none ""
    color green "==================== 成功安装 Docker CE RPM Repository ===================="
    color none ""
}

# Check Docker CE Repository Installed
function check_docker_ce_repository() {
    color none ""

    yum clean all
    yum makecache fast

    REPOSITORY_INSTALLED_NUM=$(yum list | grep -c docker-ce-stable)

    if [[ "${REPOSITORY_INSTALLED_NUM}" -gt 0 ]]; then
        color yellow "重新安装 Docker CE RPM repository ？ (y/N)"
        read -p "(Default: n):" READ_REPOSITORY_REINSTALL

        # Check Reinstall
        if [[ $(echo "${READ_REPOSITORY_REINSTALL:-n}" | tr '[a-z]' '[A-Z]') == "Y" ]]; then
            NEED_INSTALL_REPOSITORY="TRUE"
        else
            NEED_INSTALL_REPOSITORY="FALSE"
        fi
    else
        NEED_INSTALL_REPOSITORY="TRUE"
        warn "检测到未安装 Docker CE RPM repository，即将安装..."
    fi

    if [[ "${NEED_INSTALL_REPOSITORY}" == "TRUE" ]]; then
        install_docker_ce_repository
    else
        color none ""
        warn "跳过安装 Docker CE RPM repository"
        color none ""
    fi
}

# Remove Old Version of Docker
function remove_old_docker() {
    yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
}

# Install Dependencies
function install_dependencies() {
    yum install -y device-mapper-persistent-data lvm2
    if [[ $? -ne 0 ]]; then
        error "依赖安装失败"
        exit 1
    fi
}

# Install Docker CE
function install_docker_ce() {
    color none ""
    color blue "==================== 开始安装 Docker CE ===================="

    yum --enablerepo=docker-ce-stable install -y docker-ce docker-ce-cli containerd.io
    if [[ $? -ne 0 ]]; then
        error "Docker CE 安装失败"
        exit 1
    fi

    # Result
    color none ""
    color green "==================== 成功安装 Docker CE ===================="
    color none ""
}

# Configure Docker CE
function configure_docker_ce() {
    color none ""
    color blue "==================== 开始配置 Docker CE ===================="

    mkdir -p /etc/docker

    # China Server
    if [[ "${CHINA_SERVER}" == "TRUE" ]]; then
        FILE_CONF_DAEMON="/etc/docker/daemon.json"

        if [[ -f ${FILE_CONF_DAEMON} ]]; then
            warn "${FILE_CONF_DAEMON} 已存在，跳过镜像源设置"
        else
            echo '{ "registry-mirrors": [ "https://registry.docker-cn.com" ] }' > ${FILE_CONF_DAEMON}
            success "已设置 Docker CN 源作为 Docker CE 镜像源"
        fi
    fi

    # Auto Run
    systemctl enable docker.service
    systemctl restart docker.service

    # Result
    color none ""
    color green "==================== 成功配置 Docker CE ===================="
    color none ""
}

# Install Docker Compose
function install_docker_compose() {
    color none ""
    color blue "==================== 开始安装 Docker Compose ===================="

    BIN_DOCKER_COMPOSE="/usr/local/bin/docker-compose"

    # China Server
    if [[ "${CHINA_SERVER}" == "TRUE" ]]; then
        wget -c -t3 -T60 "https://get.daocloud.io/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -O ${BIN_DOCKER_COMPOSE}
    else
        wget -c -t3 -T60 "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -O ${BIN_DOCKER_COMPOSE}
    fi
    if [[ $? -ne 0 ]]; then
        rm -rf ${BIN_DOCKER_COMPOSE}
        error "Docker Compose 下载失败"
        exit 1
    fi

    chmod +x ${BIN_DOCKER_COMPOSE}

    # Result
    color none ""
    color green "==================== 成功安装 Docker Compose ===================="
    color none ""
}

# Check Docker Compose
function check_docker_compose() {
    color none ""

    BIN_DOCKER_COMPOSE="/usr/local/bin/docker-compose"

    if which ${BIN_DOCKER_COMPOSE} > /dev/null 2>&1; then
        if [[ $(${BIN_DOCKER_COMPOSE} --version | grep -oP '\d+(\.\d+)+') == ${DOCKER_COMPOSE_VERSION} ]]; then
            warn "已安装 Docker Compose ${DOCKER_COMPOSE_VERSION}，无须重新安装"

            NEED_INSTALL_DOCKER_COMPOSE="FALSE"
        else
            NEED_INSTALL_DOCKER_COMPOSE="TRUE"
        fi
    else
        NEED_INSTALL_DOCKER_COMPOSE="TRUE"
    fi

    if [[ "${NEED_INSTALL_DOCKER_COMPOSE}" == "TRUE" ]]; then
        install_docker_compose
    else
        color none ""
        warn "跳过安装 Docker Compose"
        color none ""
    fi
}

# Install
function install() {
    remove_old_docker
    install_dependencies

    install_docker_ce
    configure_docker_ce

    check_docker_compose
}

# main
function main() {
    check_system_info

    check_docker_ce_repository

    # Show Install Information
    clear
    color blue "##########################################################"
    color blue "# Auto Install Script for Docker CE"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "您将安装 Docker CE"
    color none ""
    color yellow "是否安装？ (y/N)"
    read -p "(Default: n):" READ_INSTALL

    # Check Install
    if [[ $(echo "${READ_INSTALL:-n}" | tr '[a-z]' '[A-Z]') == "Y" ]]; then
        install
    else
        color none ""
        warn "Docker CE 安装被取消，未作任何更改..."
        color none ""
    fi
}


################### Start ####################
main
################### End ####################

# Ver1.0.1
#
# - 自动添加 docker 组和用户
#
# Ver1.0.2
#
# - 支持设定服务器地址，设置为国内则自动将 Docker CE Repo 设置为阿里源，并使用国内 Docker 镜像
#
# Ver1.0.3
#
# - 防止设置源时出现目录未创建的问题
#
# Ver1.1.0
#
# - 增加安装 Docker Compose 功能
#
# Ver1.2.0
#
# - 更新 Docker CE 安装命令
# - 添加 Docker Compose 安装情况判断
# - 加速 Docker Compose 中国下载
# - 优化脚本
#
# Ver2.0.0
#
# - 优化变量命名方式
# - 拆分流程到函数中
# - 用询问替代强制重新安装依赖
# - 优化脚本
# - 更新 Docker Compose 版本
#
# Ver2.1.0
#
# - 新增日志时间显示
# - 更新 Docker Compose 版本
