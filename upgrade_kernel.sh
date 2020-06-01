#!/usr/bin/env bash
#
# For upgrade kernel-ml with ELRepo RPM repository.
#
# Version: 2.1.0
# Author: ttionya
#
# Usage:
#     bash upgrade_kernel.sh


#################### Custom Setting ####################
# 日志打印时区（留空使用服务器时区）
LOG_TIMEZONE=""
# 中国镜像
CHINA_MIRROR="FALSE"


#################### Function ####################
########################################
# Install ELRepo RPM repository.
# Arguments:
#     None
########################################
function install_elrepo_repository() {
    local CHINA_ARGUMENTS

    if [[ "${CHINA_MIRROR}" == "TRUE" ]]; then
        CHINA_ARGUMENTS="--china"
    else
        CHINA_ARGUMENTS=""
    fi

    curl ${URL_PVS_ELREPO} | bash -s -- -s --timezone "${LOG_TIMEZONE}" "${CHINA_ARGUMENTS}"
}

########################################
# Upgrade kernel.
# Arguments:
#     None
########################################
function upgrade_kernel() {
    color blue "==================== 开始升级内核 ===================="

    # remove old kernels
    rpm -e --nodeps kernel-headers
    rpm -e --nodeps kernel-tools
    rpm -e --nodeps kernel-tools-libs
    rpm -qa | grep kernel-ml | grep -v $(uname -r) | xargs -I {} yum -y remove {}

    # install
    yum --enablerepo=elrepo-kernel -y install kernel-ml kernel-ml-devel kernel-ml-headers kernel-ml-tools kernel-ml-tools-libs
    if [[ $? -ne 0 ]]; then
        error "内核升级失败"
        exit 1
    fi

    color green "==================== 成功升级内核 ===================="
}

########################################
# Configure kernel boot.
# Arguments:
#     None
########################################
function configure_kernel_boot() {
    color blue "==================== 开始配置内核启动项 ===================="

    local GRUB_DEFAULT=$(grep GRUB_DEFAULT /etc/default/grub | awk -F "=" '{print $2}')

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

    color green "==================== 成功配置内核启动项 ===================="
}

########################################
# Check whether to upgrade kernel.
# Arguments:
#     None
########################################
function check_upgrade_kernel() {
    yum clean all
    yum makecache fast

    # current kernel version
    KERNEL_VERSION_CURRENT=$(uname -r)
    KERNEL_VERSION_LATEST=$(yum --enablerepo=elrepo-kernel list | grep -P '[^@]elrepo-kernel' | grep kernel-ml.x86_64 | awk -F" " '{print $2}')

    # latest version
    if [[ -z "${KERNEL_VERSION_LATEST}" ]]; then
        warn "内核 ${KERNEL_VERSION_CURRENT} 已是最新版，无需升级"
        exit 0
    fi
}

########################################
# Check whether to reboot.
# Arguments:
#     None
########################################
function check_reboot() {
    local READ_REBOOT

    color yellow "输入 Y 立即重启系统 (y/N)"
    read -p "(Default: n):" READ_REBOOT

    # check reboot
    if [[ $(echo "${READ_REBOOT:-n}" | tr '[a-z]' '[A-Z]') == "Y" ]]; then
        reboot
    else
        warn "请手动重启系统"
    fi
}

########################################
# Show upgrade panel.
# Arguments:
#     None
# Outputs:
#     panel
########################################
function panel() {
    local READ_KERNEL_UPGRADE

    clear
    color blue "##########################################################"
    color blue "# Upgrade CentOS 7.x Kernel"
    color blue "# Author: ttionya"
    color blue "# Current Version: $(color yellow "${KERNEL_VERSION_CURRENT}")"
    color blue "# Latest Version: $(color yellow "${KERNEL_VERSION_LATEST}")"
    color blue "##########################################################"
    color yellow "您将升级内核到最新版本，此操作具有危险性，请不要在生产环境运行该脚本"
    color yellow "继续升级内核？ (y/N)"
    read -p "(Default: n):" READ_KERNEL_UPGRADE

    if [[ $(echo "${READ_KERNEL_UPGRADE:-n}" | tr '[a-z]' '[A-Z]') == "Y" ]]; then
        upgrade_kernel
        configure_kernel_boot
        check_reboot
    else
        warn "内核升级被取消，未作任何更改..."
    fi
}

# main
function main() {
    check_root
    check_os_version 7

    install_elrepo_repository

    check_upgrade_kernel

    panel
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

# v1.0.1
#
# - 修改脚本内容
#
# v1.0.2
#
# - 修复某些 VPS 上升级内核导致无法开机的问题
#
# v1.1.0
#
# - 优化升级脚本
#
# v1.1.1
#
# - 命名脚本版本
#
# v1.1.2
#
# - 优化获取最新版 kernel-ml 版本方式
#
# v1.1.3
#
# - 最新版本不会执行升级操作
# - 优化旧版本删除逻辑
#
# v1.2.0
#
# - 支持设定服务器地址，设置为国内则自动将 ElRepo 设置为清华源
#
# v1.2.1
#
# - 修复 kernel-header 未安装时导致升级失败的问题
#
# v1.2.2
#
# - 修复无法终止脚本的错误
# - 添加更多颜色支持
#
# v1.3.0
#
# - 拆分 ELRepo 安装程序
# - 优化脚本
#
# v1.3.1
#
# - 修复 GRUB 配置文件不存在导致配置失败的问题
#
# v2.0.0
#
# - 优化变量命名方式
# - 拆分流程到函数中
# - 用询问替代强制重新安装依赖
# - 优化脚本
# - 更新 ELRepo RPM Repository 版本
#
# v2.1.0
#
# - 引用外部工具方法
# - 外部工具方法支持 github 和 gitee
# - 优化脚本
