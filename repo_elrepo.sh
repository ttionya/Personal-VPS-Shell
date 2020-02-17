#!/usr/bin/env bash
#
# For install ELRepo RPM repository.
#
# Version: 2.0.0
# Author: ttionya
#
# Usage:
#     sh repo_elrepo.sh [--timezone <timezone>] [--china] [-s]


#################### Custom Setting ####################
# 日志打印时区（留空使用服务器时区）
LOG_TIMEZONE=""
# ELRepo Version
ELREPO_VERSION="7.0-4"
# 中国服务器
CHINA_SERVER="FALSE"
# 不进行询问
SILENT="FALSE"


#################### Variables ####################
while [[ $# -gt 0 ]]; do
    case "$1" in
        --timezone)
            shift
            LOG_TIMEZONE="$1"

            # Get correct timezone
            TIMEZONE_MATCHED_NUM=$(ls "/usr/share/zoneinfo/${LOG_TIMEZONE}" 2> /dev/null | wc -l)
            if [[ ${TIMEZONE_MATCHED_NUM} -ne 1 ]]; then
                LOG_TIMEZONE=$(timedatectl | grep 'Time zone' | sed -r 's@^.*\b(\w+/\w+)\b.*$@\1@')
            fi
            shift
            ;;
        --china)
            shift
            CHINA_SERVER="TRUE"
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
# Print error message (green).
# Arguments:
#     message
# Outputs:
#     Success message
########################################
function success() {
    color green "[$(TZ="${LOG_TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1"
}

########################################
# Print error message (yellow).
# Arguments:
#     message
# Outputs:
#     Warn message
########################################
function warn() {
    color yellow "[$(TZ="${LOG_TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1"
}

########################################
# Print error message (blue).
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

# Install ELRepo RPM Repository
function install_elrepo_repository() {
    color none ""
    color blue "==================== 开始安装 ELRepo RPM Repository ===================="

    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh --force http://www.elrepo.org/elrepo-release-${ELREPO_VERSION}.el7.elrepo.noarch.rpm
    if [[ $? -ne 0 ]]; then
        error "ELRepo RPM repository 安装失败"
        exit 1
    fi

    # China Server
    if [[ "${CHINA_SERVER}" == "TRUE" ]]; then
        sed -i 's@^baseurl=.*\.org/linux/\(.*\)@baseurl=https://mirrors.tuna.tsinghua.edu.cn/elrepo/\1@' /etc/yum.repos.d/elrepo.repo
        sed -i 's@^\(\thttp.*\)@#\1@' /etc/yum.repos.d/elrepo.repo
        sed -i 's@^mirrorlist=\(.*\)@#mirrorlist=\1@' /etc/yum.repos.d/elrepo.repo
        success "已设置清华大学源作为 ELRepo RPM repository 镜像源"
    fi

    # Result
    color none ""
    color green "==================== 成功安装 ELRepo RPM Repository ===================="
    color none ""
}

# Check ELRepo RPM Repository Installed
function check_elrepo_repository() {
    color none ""

    REPOSITORY_INSTALLED_NUM=$(yum list installed | grep -c elrepo-release)

    if [[ ${REPOSITORY_INSTALLED_NUM} -gt 0 ]]; then
        if [[ "${SILENT}" == "TRUE" ]]; then
            NEED_INSTALL_REPOSITORY="FALSE"
            warn "检测到已安装 ELRepo RPM repository，跳过安装"
        else
            color yellow "重新安装 ELRepo RPM repository ？ (y/N)"
            read -p "(Default: n):" READ_REPOSITORY_REINSTALL

            # Check Reinstall
            if [[ $(echo "${READ_REPOSITORY_REINSTALL:-n}" | tr [a-z] [A-Z]) == "Y" ]]; then
                NEED_INSTALL_REPOSITORY="TRUE"
            else
                NEED_INSTALL_REPOSITORY="FALSE"
            fi
        fi
    else
        NEED_INSTALL_REPOSITORY="TRUE"
        warn "检测到未安装 ELRepo RPM repository，即将安装..."
    fi

    if [[ "${NEED_INSTALL_REPOSITORY}" == "TRUE" ]]; then
        install_elrepo_repository
    else
        color none ""
        warn "跳过安装 ELRepo RPM repository"
        color none ""
    fi
}

# main
function main() {
    check_system_info

    check_elrepo_repository
}


################### Start ####################
main
################### End ####################

# Ver2.0.0
#
# - 优化变量命名方式
# - 拆分流程到函数中
# - 用询问替代强制重新安装依赖
# - 优化脚本
# - 更新 ELRepo RPM Repository 版本
# - 新增脚本执行参数
