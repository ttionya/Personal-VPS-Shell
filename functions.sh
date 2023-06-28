#!/usr/bin/env bash
#
# Common functions and variables check
#
# Version: 3.0.0
# Author: ttionya


if [[ "${PVS_INIT}" == "TRUE" ]]; then
    return
fi


#################### Variables ####################
PVS_INIT="TRUE"

COMMAND=""
for ARGS_ITEM in $*;
do
    case "${ARGS_ITEM}" in
        --china)
            CHINA_MIRROR="TRUE"
            ;;
        -y)
            ASSUME_YES="TRUE"
            ;;
        *)
            COMMAND_COUNT="$(echo "${ARGS_ITEM}" | grep -coE "^[0-9a-zA-Z]")"
            OPTIONS_COUNT="$(echo "${ARGS_ITEM}" | grep -coE "^-")"
            if [[ "${COMMAND_COUNT}" == "1" ]]; then
                if [[ -n "${COMMAND}" ]]; then
                    echo "参数错误"
                    exit 1
                fi
                COMMAND="${ARGS_ITEM^^}"
            elif [[ "${OPTIONS_COUNT}" == "1" ]]; then
                KEY="$(echo "${ARGS_ITEM%%=*}" | sed -r 's@-*(.*)@\1@' | sed 's@-@_@')" # 左侧内容
                VALUE="${ARGS_ITEM#*=}" # 右侧内容

                # 支持 (-)+option (-)+option=value 等各种松散方案
                EQUAL_COUNT="$(echo "${ARGS_ITEM}" | grep -c "=")"
                if [[ "${EQUAL_COUNT}" != "1" ]]; then
                    VALUE="TRUE"
                fi

                if [[ "${VALUE^^}" == "TRUE" ]]; then
                    VALUE="TRUE"
                fi

                export "OPTION_${KEY^^}=${VALUE}"
            else
                echo "参数错误"
                exit 1
            fi

            unset COMMAND_COUNT
            unset OPTIONS_COUNT
            unset EQUAL_COUNT
            unset KEY
            unset VALUE
            ;;
    esac
done

if [[ "${CHINA_MIRROR}" == "TRUE" ]]; then
    URL_PVS_DEVEL=""
else
    URL_PVS_DEVEL=""
fi


#################### Variables Check ####################
########################################
# Get correct timezone.
########################################
TIMEZONE="${OPTION_TIMEZONE:-"${TIMEZONE}"}"
TIMEZONE_MATCHED_COUNT="$(ls "/usr/share/zoneinfo/${TIMEZONE}" 2> /dev/null | wc -l)"
if [[ "${TIMEZONE_MATCHED_COUNT}" != "1" ]]; then
    TIMEZONE="$(cat /etc/timezone)"
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
    case "$1" in
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
    color red "[$(TZ="${TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1" >&2
}

########################################
# Print success message (green).
# Arguments:
#     message
# Outputs:
#     success message
########################################
function success() {
    color green "[$(TZ="${TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1" >&2
}

########################################
# Print warn message (yellow).
# Arguments:
#     message
# Outputs:
#     warn message
########################################
function warn() {
    color yellow "[$(TZ="${TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1" >&2
}

########################################
# Print information message (blue).
# Arguments:
#     message
# Outputs:
#     information message
########################################
function info() {
    color blue "[$(TZ="${TIMEZONE}" date +'%Y-%m-%d %H:%M:%S')] - $1" >&2
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
#     version
# Returns:
#     None / exit
########################################
function check_os_version() {
    local SYSTEM_VERSION
    local INVALID_ARRAY=()

    if [[ -s /etc/debian_version ]]; then
        SYSTEM_VERSION="$(grep -oE "[0-9.]+" /etc/debian_version)"
    else
        SYSTEM_VERSION="$(grep -oE "[0-9.]+" /etc/issue)"
    fi
    SYSTEM_MAJOR_VERSION="${SYSTEM_VERSION%%.*}"

    for MAJOR_VERSION in $*
    do
        if [[ "${SYSTEM_MAJOR_VERSION}" != "${MAJOR_VERSION}" ]]; then
            INVALID_ARRAY["${#INVALID_ARRAY[*]}"]="${MAJOR_VERSION}.x"
        fi
    done

    if [[ "${#*}" == "${#INVALID_ARRAY[*]}" ]]; then
        error "该脚本仅支持 Debian ${INVALID_ARRAY[*]} 版本"
        exit 1
    fi
}


#################### Function (Overwrite) ####################
if [[ "$(type -t main)" != "function" ]]; then
    function main() {
        warn "没有找到 main 方法，跳过执行"
    }
fi


#################### Function (Other) ####################
########################################
# Get the number of CPU cores.
# Arguments:
#     None
########################################
function get_cpu_number() {
    CPU_NUMBER="$(grep -c "processor" /proc/cpuinfo)"
}


#################### Start ####################
main $*
COMMAND="${COMMAND:-"${DEFAULT_COMMAND}"}"
if [[ "$(type -t "${COMMAND,,}")" == "function" ]]; then
    ${COMMAND,,} $*
else
    error "无效命令: ${COMMAND,,}"
    exit 1
fi
#################### End ####################


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
#
# v2.0.0
#
# - 支持解析输入，自动选择执行方法
# - 支持兜底函数
#
# v2.1.0
#
# - 处理参数格式化问题
# - 优化获得 CPU 核心数方法
#
# v2.2.0
#
# - 暴露系统主要版本全局变量
#
# v3.0.0
#
# - 修改为 Debian 版
