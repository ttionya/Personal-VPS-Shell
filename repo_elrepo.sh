#!/usr/bin/env bash
#
# For install ELRepo RPM repository.
#
# Version: 2.1.0
# Author: ttionya
#
# Usage:
#     bash repo_elrepo.sh [--timezone <timezone>] [--china] [-s]


#################### Custom Setting ####################
# 日志打印时区（留空使用服务器时区）
LOG_TIMEZONE=""
# 中国镜像
CHINA_MIRROR="FALSE"
# 不进行询问
SILENT="FALSE"


#################### Variables ####################
while [[ $# -gt 0 ]]; do
    case "$1" in
        --timezone)
            shift
            LOG_TIMEZONE="$1"
            shift
            ;;
        --china)
            shift
            CHINA_MIRROR="TRUE"
            ;;
        -s)
            shift
            SILENT="TRUE"
            ;;
        *)
            break
            ;;
    esac
done


#################### Function ####################
########################################
# Install ELRepo RPM repository.
# Arguments:
#     None
########################################
function install_elrepo_repository() {
    color blue "==================== 开始安装 ELRepo RPM Repository ===================="

    # remove old repository
    if [[ "${REPOSITORY_INSTALLED}" == "TRUE" ]]; then
        yum -y remove elrepo-release
    fi

    # install new repository
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    yum -y install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
    if [[ $? -ne 0 ]]; then
        error "ELRepo RPM repository 安装失败"
        exit 1
    fi

    color green "==================== 成功安装 ELRepo RPM Repository ===================="
}

########################################
# Configure repository china mirror.
# Arguments:
#     None
########################################
function configure_china_mirror() {
    if [[ "${CHINA_MIRROR}" == "TRUE" ]]; then
        sed -i 's@^baseurl=.*\.org/linux/\(.*\)@baseurl=https://mirrors.tuna.tsinghua.edu.cn/elrepo/\1@' /etc/yum.repos.d/elrepo.repo
        sed -i 's@^\(\thttp.*\)@#\1@' /etc/yum.repos.d/elrepo.repo
        sed -i 's@^mirrorlist=\(.*\)@#mirrorlist=\1@' /etc/yum.repos.d/elrepo.repo

        success "已设置清华大学源作为 ELRepo RPM repository 镜像源"
    fi
}

########################################
# Configure repository status.
# Arguments:
#     None
########################################
function configure_repository_status() {
    yum-config-manager --enable elrepo
    yum-config-manager --disable elrepo-kernel

    success "已启用 [elrepo] 并禁用 [elrepo-kernel]"
}

########################################
# Configure ELRepo RPM repository.
# Arguments:
#     None
########################################
function configure_main() {
    color blue "==================== 开始配置 ELRepo RPM Repository ===================="

    # install dependencies
    yum -y install yum-utils

    configure_china_mirror
    configure_repository_status

    color green "==================== 成功配置 ELRepo RPM Repository ===================="
}

########################################
# Check whether to install the repository.
# Globals:
#     REPOSITORY_INSTALLED
# Arguments:
#     None
########################################
function check_elrepo_repository() {
    local NEED_INSTALL_REPOSITORY
    local READ_REPOSITORY_REINSTALL

    # check repository installed
    local REPOSITORY_INSTALLED_COUNT=$(rpm -qa | grep -c elrepo-release)
    if [[ ${REPOSITORY_INSTALLED_COUNT} -gt 0 ]]; then
        REPOSITORY_INSTALLED="TRUE"
    else
        REPOSITORY_INSTALLED="FALSE"
    fi

    if [[ "${REPOSITORY_INSTALLED}" == "TRUE" ]]; then
        if [[ "${SILENT}" == "TRUE" ]]; then
            NEED_INSTALL_REPOSITORY="FALSE"
            warn "检测到已安装的 ELRepo RPM repository"
        else
            color yellow "重新安装 ELRepo RPM repository ？ (y/N)"
            read -p "(Default: n):" READ_REPOSITORY_REINSTALL

            # check reinstall
            if [[ $(echo "${READ_REPOSITORY_REINSTALL:-n}" | tr [a-z] [A-Z]) == "Y" ]]; then
                NEED_INSTALL_REPOSITORY="TRUE"
            else
                NEED_INSTALL_REPOSITORY="FALSE"
            fi
        fi
    else
        NEED_INSTALL_REPOSITORY="TRUE"
        warn "未检测到已安装的 ELRepo RPM repository，即将安装..."
    fi

    if [[ "${NEED_INSTALL_REPOSITORY}" == "TRUE" ]]; then
        install_elrepo_repository
        configure_main
    else
        warn "跳过安装 ELRepo RPM repository"
    fi
}

# main
function main() {
    check_root
    check_os_version 7

    check_elrepo_repository
}

# dep
function dep() {
    local FUNCTION_URL

    if [[ "${CHINA_MIRROR}" == "TRUE" ]]; then
        FUNCTION_URL="https://gitee.com/ttionya/Personal-VPS-Shell/raw/master/functions.sh"
    else
        FUNCTION_URL="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/functions.sh"
    fi

    source <(curl -s ${FUNCTION_URL})
    if [[ "${PVS_INIT}" != "TRUE" ]]; then
        echo "依赖文件下载失败，请重试..."
        exit 1
    fi
}


################### Start ####################
dep
main

echo ""
################### End ####################

# v2.0.0
#
# - 优化变量命名方式
# - 拆分流程到函数中
# - 用询问替代强制重新安装依赖
# - 优化脚本
# - 更新 ELRepo RPM Repository 版本
# - 新增脚本执行参数
#
# v2.1.0
#
# - 引用外部工具方法
# - 外部工具方法支持 github 和 gitee
# - 优化脚本
# - 启用 elrepo，禁用 elrepo-kernel
