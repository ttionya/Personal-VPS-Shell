#!/usr/bin/env bash
#
# Common functions and variables check
#
# Version: 1.1.0
# Author: ttionya


if [[ "${PVS_INIT}" == "TRUE" ]]; then
    return
fi


#################### Variables ####################
PVS_INIT="TRUE"
if [[ "${CHINA_MIRROR}" == "TRUE" ]]; then
    URL_PVS_DEVEL="https://gitee.com/ttionya/Personal-VPS-Shell/raw/master/lamp_devel.sh"
    URL_PVS_ELREPO="https://gitee.com/ttionya/Personal-VPS-Shell/raw/master/repo_elrepo.sh"
    URL_PVS_EPEL="https://gitee.com/ttionya/Personal-VPS-Shell/raw/master/repo_epel.sh"
else
    URL_PVS_DEVEL="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/lamp_devel.sh"
    URL_PVS_ELREPO="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/repo_elrepo.sh"
    URL_PVS_EPEL="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/repo_epel.sh"
fi


#################### Variables Check ####################
########################################
# Get correct timezone.
########################################
TIMEZONE_MATCHED_COUNT=$(ls "/usr/share/zoneinfo/${LOG_TIMEZONE}" 2> /dev/null | wc -l)
if [[ "${TIMEZONE_MATCHED_COUNT}" -ne 1 ]]; then
    LOG_TIMEZONE=$(timedatectl | grep 'Time zone' | sed 's@Time zone:@@' | awk -F' ' '{ print $1 }')
fi
unset TIMEZONE_MATCHED_COUNT


#################### Function (Print) ####################
########################################
# Print colorful message.
# Arguments:
#     color
#     message
# Outputs:
#     colorful message
########################################
function color() {
    case $1 in
        red)     echo -e "\033[31m$2\033[0m" ;;
        green)   echo -e "\033[32m$2\033[0m" ;;
        yellow)  echo -e "\033[33m$2\033[0m" ;;
        blue)    echo -e "\033[34m$2\033[0m" ;;
        none)    echo "$2" ;;
    esac
}

########################################
# Print error message (red).
# Arguments:
#     message
# Outputs:
#     error message
########################################
function error() {
    color red "[$(TZ="${LOG_TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1" >&2
}

########################################
# Print success message (green).
# Arguments:
#     message
# Outputs:
#     success message
########################################
function success() {
    color green "[$(TZ="${LOG_TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1" >&2
}

########################################
# Print warn message (yellow).
# Arguments:
#     message
# Outputs:
#     warn message
########################################
function warn() {
    color yellow "[$(TZ="${LOG_TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1" >&2
}

########################################
# Print information message (blue).
# Arguments:
#     message
# Outputs:
#     information message
########################################
function info() {
    color blue "[$(TZ="${LOG_TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1" >&2
}


#################### Function (Check) ####################
########################################
# Check root user.
# Arguments:
#     None
# Returns:
#     None / exit
########################################
function check_root() {
    if [[ "${EUID}" != "0" ]]; then
        error "该脚本必须以 root 权限运行"
        exit 1
    fi
}

########################################
# Check OS version.
# Arguments:
#     version (7, 8)
# Returns:
#     None / exit
########################################
function check_os_version() {
    local SYSTEM_VERSION
    local INVALID_ARRAY=()

    if [[ -s /etc/redhat-release ]]; then
        SYSTEM_VERSION="$(grep -oE "[0-9.]+" /etc/redhat-release)"
    else
        SYSTEM_VERSION="$(grep -oE "[0-9.]+" /etc/issue)"
    fi
    SYSTEM_VERSION="${SYSTEM_VERSION%%.*}"

    for VERSION in $*
    do
        if [[ "${SYSTEM_VERSION}" != "${VERSION}" ]]; then
            INVALID_ARRAY["${#INVALID_ARRAY[*]}"]="${VERSION}.x"
        fi
    done

    if [[ "${#*}" -eq "${#INVALID_ARRAY[*]}" ]]; then
        error "该脚本仅支持 CentOS ${INVALID_ARRAY[*]} 版本"
        exit 1
    fi
}

#################### Function (Other) ####################
########################################
# Get the number of CPU cores.
# Arguments:
#     None
########################################
function get_cpu_number() {
    CPU_NUMBER=$(cat /proc/cpuinfo | grep -c 'processor')
}

# v1.0.1
#
# - 修复文件换行符问题
#
# v1.0.2
#
# - 中国服务器使用 gitee 地址
#
# v1.0.3
#
# - 优化系统版本校验脚本，支持同时判断多个系统版本
#
# v1.1.0
#
# - 添加计算 CPU 核心数函数
# - 优化获得当前时区的方法
# - 优化代码写法
