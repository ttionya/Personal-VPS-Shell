#!/usr/bin/env bash
#
# For upgrade kernel-ml with ELRepo RPM repository.
#
# Version: 2.0.0
# Author: ttionya
#
# Usage:
#     sh upgrade_kernel.sh


#################### Custom Setting ####################
# 日志打印时区（留空使用服务器时区）
LOG_TIMEZONE=""
# 中国服务器
CHINA_SERVER="FALSE"


#################### Variables ####################
# Timezone
TIMEZONE_MATCHED_NUM=$(ls "/usr/share/zoneinfo/${LOG_TIMEZONE}" 2> /dev/null | wc -l)
if [[ ${TIMEZONE_MATCHED_NUM} -ne 1 ]]; then
    LOG_TIMEZONE=$(timedatectl | grep 'Time zone' | sed -r 's@^.*\b(\w+/\w+)\b.*$@\1@')
fi


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

# Install ELRepo RPM Repository
function install_elrepo_repository() {
    local CHINA_SERVER_ARGUMENTS
    if [[ "${CHINA_SERVER}" == "TRUE" ]]; then
        CHINA_SERVER_ARGUMENTS="--china"
    else
        CHINA_SERVER_ARGUMENTS=""
    fi

    curl https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/repo_elrepo.sh | \
        bash -s -- -s --timezone "${LOG_TIMEZONE}" "${CHINA_SERVER_ARGUMENTS}"
}

# Upgrade Kernel
function upgrade_kernel() {
    color none ""
    color blue "==================== 开始升级内核 ===================="

    # Remove Old Kernel
    rpm -e --nodeps kernel-headers
    rpm -e --nodeps kernel-tools
    rpm -e --nodeps kernel-tools-libs
    rpm -qa | grep kernel-ml | grep -v `uname -r` | xargs -I {} yum remove -y {}

    # Install
    yum --enablerepo=elrepo-kernel -y install kernel-ml kernel-ml-devel kernel-ml-headers kernel-ml-tools kernel-ml-tools-libs
    if [[ $? -ne 0 ]]; then
        error "Kernel 升级失败"
        exit 1
    fi

    # Result
    color none ""
    color green "==================== 成功升级内核 ===================="
    color none ""
}

# Configure Kernel Boot
function configure_kernel_boot() {
    color none ""
    color blue "==================== 开始配置内核启动项 ===================="

    GRUB_DEFAULT=$(grep GRUB_DEFAULT /etc/default/grub | awk -F "=" '{print $2}')

    if [[ "${GRUB_DEFAULT}" == "saved" ]]; then
        # 如果不存在先生成
        if [[ ! -f /boot/grub2/grub.cfg ]]; then
            info "配置文件不存在，生成配置文件 /boot/grub2/grub.cfg"
            grub2-mkconfig -o /boot/grub2/grub.cfg
        fi
        grep -P -m 1 "^menuentry" /boot/grub2/grub.cfg | awk -F "'" '{print $2}' | xargs -I {} grub2-set-default {}
    else
        sed -i 's@^GRUB_DEFAULT=\(.*\)@GRUB_DEFAULT=0@' /etc/default/grub
        grub2-mkconfig -o /boot/grub2/grub.cfg
    fi

    # Result
    color none ""
    color green "==================== 成功配置内核启动项 ===================="
    color none ""
}

# Upgrade
function upgrade() {
    upgrade_kernel
    configure_kernel_boot

    color yellow "输入 Y 立即重启系统 (y/N)"
    read -p "(Default: n):" READ_REBOOT

    # Check Reboot
    if [[ $(echo "${READ_REBOOT:-n}" | tr '[a-z]' '[A-Z]') == "Y" ]]; then
        reboot
    else
        color none ""
        warn "请手动重启系统"
        color none ""
    fi
}

# Check Kernel Version
function check_upgrade_kernel() {
    color none ""

    yum clean all
    yum makecache fast

    # Check Current Kernel Version
    KERNEL_VERSION_CURRENT=$(uname -r)
    KERNEL_VERSION_LATEST=$(yum --enablerepo=elrepo-kernel list | grep -P '[^@]elrepo-kernel' | grep kernel-ml.x86_64 | awk -F" " '{print $2}')

    # 最新版无需升级
    if [[ -z "${KERNEL_VERSION_LATEST}" ]]; then
        color none ""
        warn "内核 ${KERNEL_VERSION_CURRENT} 已是最新版，无需升级"
        exit 0
    fi
}

# main
function main() {
    check_system_info

    install_elrepo_repository

    check_upgrade_kernel

    # Show Upgrade Information
    clear
    color blue "##########################################################"
    color blue "# Upgrade CentOS 7.X Kernel"
    color blue "# Author: ttionya"
    color blue "# Current Version: $(color yellow "${KERNEL_VERSION_CURRENT}")"
    color blue "# Latest Version: $(color yellow "${KERNEL_VERSION_LATEST}")"
    color blue "##########################################################"
    color none ""
    color yellow "您将升级内核到最新版本，此操作具有危险性，请不要在生产环境运行该脚本"
    color none ""
    color yellow "继续升级内核？ (y/N)"
    read -p "(Default: n):" READ_KERNEL_UPGRADE

    # Check Upgrade
    if [[ $(echo "${READ_KERNEL_UPGRADE:-n}" | tr '[a-z]' '[A-Z]') == "Y" ]]; then
        upgrade
    else
        color none ""
        warn "内核升级被取消，未作任何更改..."
        color none ""
    fi
}


################### Start ####################
main
################### End ####################

# Ver1.0.1
#
# - 修改脚本内容
#
# Ver1.0.2
#
# - 修复某些 VPS 上升级内核导致无法开机的问题
#
# Ver1.1.0
#
# - 优化升级脚本
#
# Ver1.1.1
#
# - 命名脚本版本
#
# Ver1.1.2
#
# - 优化获取最新版 kernel-ml 版本方式
#
# Ver1.1.3
#
# - 最新版本不会执行升级操作
# - 优化旧版本删除逻辑
#
# Ver1.2.0
#
# - 支持设定服务器地址，设置为国内则自动将 ElRepo 设置为清华源
#
# Ver1.2.1
#
# - 修复 kernel-header 未安装时导致升级失败的问题
#
# Ver1.2.2
#
# - 修复无法终止脚本的错误
# - 添加更多颜色支持
#
# Ver1.3.0
#
# - 拆分 ELRepo 安装程序
# - 优化脚本
#
# Ver1.3.1
#
# - 修复 GRUB 配置文件不存在导致配置失败的问题
#
# Ver2.0.0
#
# - 优化变量命名方式
# - 拆分流程到函数中
# - 用询问替代强制重新安装依赖
# - 优化脚本
# - 更新 ELRepo RPM Repository 版本
