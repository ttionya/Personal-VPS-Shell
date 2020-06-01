#!/usr/bin/env bash
#
# Common functions and variables check
#
# Version: 1.0.1
# Author: ttionya


if [[ "${PVS_INIT}" == "TRUE" ]]; then
    return
fi


#################### Variables ####################
PVS_INIT="TRUE"
URL_PVS_DEVEL="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/lamp_devel.sh"
URL_PVS_ELREPO="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/repo_elrepo.sh"
URL_PVS_EPEL="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/repo_epel.sh"


#################### Variables Check ####################
########################################
# Get correct timezone.
########################################
TIMEZONE_MATCHED_COUNT=$(ls "/usr/share/zoneinfo/${LOG_TIMEZONE}" 2> /dev/null | wc -l)
if [[ ${TIMEZONE_MATCHED_COUNT} -ne 1 ]]; then
    LOG_TIMEZONE=$(timedatectl | grep 'Time zone' | sed -r 's@^.*\b(\w+/\w+)\b.*$@\1@')
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
        none)    echo $2 ;;
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

    if [[ -s /etc/redhat-release ]]; then
        SYSTEM_VERSION="$(grep -oE "[0-9.]+" /etc/redhat-release)"
    else
        SYSTEM_VERSION="$(grep -oE "[0-9.]+" /etc/issue)"
    fi
    SYSTEM_VERSION=${SYSTEM_VERSION%%.*}

    if [[ "${SYSTEM_VERSION}" != "$1" ]]; then
        error "该脚本仅支持 CentOS $1.x 版本"
        exit 1
    fi
}

# v1.0.1
#
# - 修复文件换行符问题
