#!/usr/bin/env bash
#
# Docker (Community Edition) and Docker Compose with Docker CE repository
#
# Version: 4.0.0
# Author: ttionya
#
# Usage:
#     sh pvs_docker_ce.sh [ install | configure | update | uninstall ] [ [options] ]
#
# https://docs.docker.com/engine/install/debian/


#################### Custom Setting ####################
DEFAULT_COMMAND="INSTALL"
# 时区（留空使用服务器时区）
TIMEZONE=""
# 中国镜像
CHINA_MIRROR="FALSE"


#################### Variables ####################
REPO_CONFIG_FILE="/etc/apt/sources.list.d/docker.list"
DOCKER_CONFIG_DIR="/etc/docker"
DOCKER_CONFIG_FILE="${DOCKER_CONFIG_DIR}/daemon.json"


#################### Function ####################
########################################
# Check that Docker CE is installed.
# Arguments:
#     None
########################################
function check_installed() {
    if dpkg -s "docker-ce" > /dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

########################################
# Check that Docker CE repository is installed.
# Arguments:
#     None
########################################
function check_repo_installed() {
    if [[ ! -f "${REPO_CONFIG_FILE}" ]]; then
        error "未发现 Docker CE repository"
        exit 1
    fi
}

########################################
# Install Docker CE repository.
# Arguments:
#     None
########################################
function install_repo_repository() {
    local URL_PVS_REPO="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/debian/repo_docker_ce.sh"
    local CHINA_ARGUMENTS=""
    local Y_ARGUMENTS=""

    if [[ "${CHINA_MIRROR}" == "TRUE" ]]; then
        URL_PVS_REPO="https://gitee.com/ttionya/Personal-VPS-Shell/raw/debian/repo_docker_ce.sh"
        CHINA_ARGUMENTS="--china"
    fi
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        Y_ARGUMENTS="-y"
    fi

    bash <(curl -m 10 --retry 5 "${URL_PVS_REPO}") --install-only --timezone="${TIMEZONE}" "${CHINA_ARGUMENTS}" "${Y_ARGUMENTS}"
    if [[ "$?" != "0" ]]; then
        error "安装 Docker CE repository 失败"
        exit 1
    fi
}

########################################
# Uninstall Old Docker.
# Arguments:
#     None
########################################
function uninstall_old_docker() {
    color blue "========================================"
    info "卸载旧 Docker 中..."

    apt-get -y purge containerd docker.io docker-compose docker-doc podman-docker runc
    if [[ "$?" != "0" ]]; then
        error "卸载旧 Docker 失败"
        exit 1
    fi

    success "卸载旧 Docker 完成"
}

# install main
function install_main() {
    color blue "========================================"
    info "安装 Docker CE 中..."

    apt-get -y update
    apt-get -y install containerd.io docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
    if [[ "$?" != "0" ]]; then
        error "安装 Docker CE 失败"
        exit 1
    fi

    success "安装 Docker CE 成功"
}

# configure main
function configure_main() {
    color blue "========================================"
    info "配置 Docker CE 中..."

    # https://github.com/docker-practice/docker-registry-cn-mirror-test/actions
    local REGISTRY_MIRRORS='"registry-mirrors": [ "https://hub-mirror.c.163.com", "https://mirror.baidubce.com" ]'

    mkdir -p "${DOCKER_CONFIG_DIR}"

    if [[ "${CHINA_MIRROR}" == "TRUE" ]]; then
        if [[ -f "${DOCKER_CONFIG_FILE}" ]]; then
            warn "${DOCKER_CONFIG_FILE} 已存在，跳过镜像源设置"
            warn "请手动添加 ${REGISTRY_MIRRORS}"
        else
            echo "{ ${REGISTRY_MIRRORS} }" > "${DOCKER_CONFIG_FILE}"
            success "已设置网易云和百度源作为 Docker CE 镜像源"
        fi
    fi

    systemctl enable docker.service
    systemctl restart docker.service

    success "配置 Docker CE 完成"
}

# uninstall main
function uninstall_main() {
    color blue "========================================"
    info "卸载 Docker CE 中..."

    # 获得已安装信息
    local DOCKER_IMAGES="$(docker image ls --format '{{.Repository}}:{{.Tag}}')"
    local DOCKER_CONTAINERS="$(docker container ls --format '{{.Image}}')"
    local DOCKER_VOLUMES="$(docker volume ls --format '{{.Name}}')"

    apt-get -y purge containerd.io docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
    if [[ "$?" != "0" ]]; then
        error "卸载 Docker CE 失败"
        exit 1
    fi

    if [[ -n "${DOCKER_IMAGES}" ]]; then
        color yellow "以下 image 未被删除"
        color blue "${DOCKER_IMAGES}"
    fi
    if [[ -n "${DOCKER_CONTAINERS}" ]]; then
        color yellow "以下 container 未被删除"
        color blue "${DOCKER_CONTAINERS}"
    fi
    if [[ -n "${DOCKER_VOLUMES}" ]]; then
        color yellow "以下 volume 未被删除"
        color blue "${DOCKER_VOLUMES}"
    fi

    color yellow "你可能需要手动执行以下命令："
    color yellow "rm -rf /var/lib/docker"
    color yellow "rm -rf /var/lib/containerd"

    success "卸载 Docker CE 完成"
}

# install
function install() {
    check_installed
    if [[ "$?" == "1" ]]; then
        color yellow "发现已安装的 Docker CE，你可以："
        color yellow "1. 使用 update 升级版本"
        color yellow "2. 使用 uninstall 卸载后重新使用 install 安装"
        exit 1
    fi

    install_repo_repository
    check_repo_installed

    local READ_DOCKER_CE_INSTALL

    clear
    color blue "##########################################################"
    color blue "# Auto Install Script for Docker CE and Docker Compose"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将安装 Docker CE 和 Docker Compose"
    color none ""
    color yellow "确认安装？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_DOCKER_CE_INSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_DOCKER_CE_INSTALL
    fi

    if [[ "${READ_DOCKER_CE_INSTALL^^}" == "Y" ]]; then
        uninstall_old_docker
        install_main
        configure_main
    else
        info "已取消 Docker CE 安装"
    fi
}

# configure
function configure() {
    check_installed
    if [[ "$?" == "0" ]]; then
        color yellow "未发现已安装的 Docker CE，你可以使用 install 安装"
        exit 1
    fi

    local READ_DOCKER_CE_CONFIGURE

    clear
    color blue "##########################################################"
    color blue "# Auto Configure Script for Docker CE"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将配置 Docker CE"
    color none ""
    color yellow "确认配置？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_DOCKER_CE_CONFIGURE="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_DOCKER_CE_CONFIGURE
    fi

    if [[ "${READ_DOCKER_CE_CONFIGURE^^}" == "Y" ]]; then
        configure_main
    else
        info "已取消 Docker CE 配置"
    fi
}

# update
function update() {
    check_installed
    if [[ "$?" == "0" ]]; then
        color yellow "未发现已安装的 Docker CE，你可以使用 install 安装"
        exit 1
    fi

    install_repo_repository
    check_repo_installed

    local READ_DOCKER_CE_UPDATE

    clear
    color blue "##########################################################"
    color blue "# Auto Update Script for Docker CE and Docker Compose"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将升级 Docker CE 和 Docker Compose"
    color none ""
    color yellow "确认升级？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_DOCKER_CE_UPDATE="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_DOCKER_CE_UPDATE
    fi

    if [[ "${READ_DOCKER_CE_UPDATE^^}" == "Y" ]]; then
        install_main
    else
        info "已取消 Docker CE 升级"
    fi
}

# uninstall
function uninstall() {
    check_installed
    if [[ "$?" == "0" ]]; then
        color yellow "未发现已安装的 Docker CE"
        exit 1
    fi

    local READ_DOCKER_CE_UNINSTALL

    clear
    color blue "##########################################################"
    color blue "# Auto Uninstall Script for Docker CE and Docker Compose"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将卸载 Docker CE 和 Docker Compose"
    color none ""
    color yellow "确认卸载？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_DOCKER_CE_UNINSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_DOCKER_CE_UNINSTALL
    fi

    if [[ "${READ_DOCKER_CE_UNINSTALL^^}" == "Y" ]]; then
        uninstall_main
    else
        info "已取消 Docker CE 卸载"
    fi
}

# main
function main() {
    check_root
    check_os_version 11 12
}

# dep
function dep() {
    local FUNCTION_URL="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/debian/functions.sh"

    for ARGS_ITEM in $*;
    do
        if [[ "${ARGS_ITEM}" == "--china" ]]; then
            CHINA_MIRROR="TRUE"
            FUNCTION_URL="https://gitee.com/ttionya/Personal-VPS-Shell/raw/debian/functions.sh"
        fi
    done

    source <(curl -sS -m 10 --retry 5 "${FUNCTION_URL}")
    if [[ "${PVS_INIT}" != "TRUE" ]]; then
        echo "依赖文件下载失败，请重试..."
        exit 1
    fi
}


#################### Start ####################
dep $*
#################### End ####################


# v1.0.1
#
# - 自动添加 docker 组和用户
#
# v1.0.2
#
# - 支持设定服务器地址，设置为国内则自动将 Docker CE Repo 设置为阿里源，并使用国内 Docker 镜像
#
# v1.0.3
#
# - 防止设置源时出现目录未创建的问题
#
# v1.1.0
#
# - 增加安装 Docker Compose 功能
#
# v1.2.0
#
# - 更新 Docker CE 安装命令
# - 添加 Docker Compose 安装情况判断
# - 加速 Docker Compose 中国下载
# - 优化脚本
#
# v2.0.0
#
# - 优化变量命名方式
# - 拆分流程到函数中
# - 用询问替代强制重新安装依赖
# - 优化脚本
# - 更新 Docker Compose 版本
#
# v2.1.0
#
# - 新增日志时间显示
# - 更新 Docker Compose 版本
#
# v3.0.0
#
# - 重构脚本
# - 更新 Docker Compose 版本
#
# v4.0.0
#
# - 修改为 Debian 版
# - 修改 Docker Compose 安装方式
