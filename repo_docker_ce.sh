#!/usr/bin/env bash
#
# Docker CE repository
#
# Version: 2.0.1
# Author: ttionya
#
# Usage:
#     bash repo_docker_ce.sh [ install | configure | uninstall ] [ [options] | --install-only ]


#################### Custom Setting ####################
DEFAULT_COMMAND="INSTALL"
# 时区（留空使用服务器时区）
TIMEZONE=""
# 中国镜像
CHINA_MIRROR="FALSE"


#################### Variables ####################
REPO_CONFIG_FILE="/etc/apt/sources.list.d/docker.list"
REPO_GPG_FILE="/etc/apt/keyrings/docker.gpg"


#################### Function ####################
########################################
# Check that Docker CE repository is installed.
# Arguments:
#     None
########################################
function check_installed() {
    if [[ -f "${REPO_CONFIG_FILE}" ]]; then
        REPO_INSTALLED="TRUE"
        return 1
    else
        return 0
    fi
}

########################################
# Install dependencies.
# Arguments:
#     None
########################################
function install_dependencies() {
    color blue "========================================"
    info "依赖安装中..."

    apt-get -y update
    apt-get -y install ca-certificates curl gnupg
    if [[ "$?" != "0" ]]; then
        error "依赖安装失败"
        exit 1
    fi

    success "依赖安装成功"
}

# install main
function install_main() {
    color blue "========================================"
    info "安装 Docker CE repository 中..."

    mkdir -p "$(dirname "${REPO_GPG_FILE}")"
    rm -rf "${REPO_GPG_FILE}"

    # download GPG
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o "${REPO_GPG_FILE}"
    if [[ "$?" != "0" ]]; then
        error "安装 Docker CE repository 失败"
        exit 1
    fi
    chmod a+r "${REPO_GPG_FILE}"

    # configure
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${REPO_GPG_FILE}] https://download.docker.com/linux/debian $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" > "${REPO_CONFIG_FILE}"

    success "安装 Docker CE repository 成功"
}

# configure main
function configure_main() {
    color blue "========================================"
    info "配置 Docker CE repository 中..."

    if [[ "${CHINA_MIRROR}" == "TRUE" ]]; then
        sed -i 's@^deb \(.*\)https://download.docker.com/linux/debian\(.*\)@deb \1https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian\2@' "${REPO_CONFIG_FILE}"

        success "已设置清华大学源作为 Docker CE repository 镜像源"
    fi

    success "配置 Docker CE repository 完成"
}

# uninstall main
function uninstall_main() {
    color blue "========================================"
    info "卸载 Docker CE repository 中..."

    rm -rf "${REPO_CONFIG_FILE}" "${REPO_GPG_FILE}"

    apt -y update

    success "卸载 Docker CE repository 完成"
}

# install
function install() {
    check_installed

    local READ_REPO_INSTALL
    local INSTALL_TEXT="安装"

    if [[ "${REPO_INSTALLED}" == "TRUE" ]]; then
        # 只允许安装
        if [[ "${OPTION_INSTALL_ONLY}" == "TRUE" ]]; then
            warn "检测到已安装 Docker CE repository，跳过"
            exit 0
        fi

        INSTALL_TEXT="重新安装"
    fi

    clear
    color blue "##########################################################"
    color blue "# Auto Install Script for Docker CE Repository"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将${INSTALL_TEXT} Docker CE repository"
    color none ""
    color yellow "确认${INSTALL_TEXT}？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_REPO_INSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_REPO_INSTALL
    fi

    if [[ "${READ_REPO_INSTALL^^}" == "Y" ]]; then
        install_dependencies
        if [[ "${REPO_INSTALLED}" == "TRUE" ]]; then
            uninstall_main
        fi
        install_main
        configure_main
    else
        info "已取消 Docker CE repository ${INSTALL_TEXT}"
    fi
}

# configure
function configure() {
    check_installed
    if [[ "$?" == "0" ]]; then
        color yellow "未发现已安装的 Docker CE repository，你可以使用 install 安装"
        exit 1
    fi

    local READ_REPO_CONFIGURE

    clear
    color blue "##########################################################"
    color blue "# Auto Configure Script for Docker CE Repository"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将配置 Docker CE repository"
    color none ""
    color yellow "确认配置？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_REPO_CONFIGURE="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_REPO_CONFIGURE
    fi

    if [[ "${READ_REPO_CONFIGURE^^}" == "Y" ]]; then
        configure_main
    else
        info "已取消 Docker CE repository 配置"
    fi
}

# uninstall
function uninstall() {
    check_installed
    if [[ "$?" == "0" ]]; then
        color yellow "未发现已安装的 Docker CE repository"
        exit 1
    fi

    local READ_REPO_UNINSTALL

    clear
    color blue "##########################################################"
    color blue "# Auto Uninstall Script for Docker CE Repository"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将卸载 Docker CE repository"
    color none ""
    color yellow "确认卸载？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_REPO_UNINSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_REPO_UNINSTALL
    fi

    if [[ "${READ_REPO_UNINSTALL^^}" == "Y" ]]; then
        uninstall_main
    else
        info "已取消 Docker CE repository 卸载"
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


# v1.0.0
#
# - 拆分安装 Docker CE repository 功能
#
# v2.0.0
#
# - 修改为 Debian 版
#
# v2.0.1
#
# - 使用 apt-get 替代 apt
