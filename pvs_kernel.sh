#!/usr/bin/env bash
#
# kernel-ml with ELRepo RPM repository
#
# Version: 3.0.0
# Author: ttionya
#
# Usage:
#     bash pvs_kernel.sh [ upgrade | uninstall ] [ [options] ]


#################### Custom Setting ####################
DEFAULT_COMMAND="UPGRADE"
# 时区（留空使用服务器时区）
TIMEZONE=""
# 中国镜像
CHINA_MIRROR="FALSE"


#################### Variables ####################
BOOT_GRUB_CONFIG_FILE="/boot/grub2/grub.cfg"
BOOT_GRUB_DEFAULT_FILE="/etc/default/grub"


#################### Function ####################
########################################
# Check that ELRepo RPM repository is installed.
# Arguments:
#     None
########################################
function check_elrepo_installed() {
    local ELREPO_INSTALLED_COUNT=$(rpm -qa | grep -c 'elrepo-release')
    if [[ "${ELREPO_INSTALLED_COUNT}" == "0" ]]; then
        error "未发现必要依赖 ELRepo RPM Repository"
        exit 1
    fi
}

########################################
# Check that kernel needs upgrade.
# Arguments:
#     None
########################################
function check_upgrade() {
    yum clean all
    yum makecache fast

    # kernel version
    KERNEL_VERSION_CURRENT="$(uname -r)"
    KERNEL_VERSION_LATEST=$(yum --enablerepo=elrepo-kernel list | grep -P '[^@]elrepo-kernel' | grep kernel-ml.x86_64 | awk -F' ' '{ print $2 }')

    # latest version
    if [[ -z "${KERNEL_VERSION_LATEST}" ]]; then
        warn "内核 ${KERNEL_VERSION_CURRENT} 已是最新版，无需升级"
        exit 0
    fi
}

########################################
# Ask for an immediate reboot.
# Arguments:
#     None
########################################
function ask_reboot() {
    local READ_REBOOT

    color yellow "立即重启系统？ (y/N)"
    read -p "(Default: n):" READ_REBOOT

    if [[ "${READ_REBOOT^^}" == "Y" ]]; then
        reboot
    else
        warn "请手动重启系统"
    fi
}

########################################
# Install ELRepo RPM repository.
# Arguments:
#     None
########################################
function install_elrepo_repository() {
    local CHINA_ARGUMENTS=""
    local Y_ARGUMENTS=""

    if [[ "${CHINA_MIRROR}" == "TRUE" ]]; then
        CHINA_ARGUMENTS="--china"
    fi
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        Y_ARGUMENTS="-y"
    fi

    bash <(curl -m 10 --retry 5 "${URL_PVS_ELREPO}") --install-only --timezone="${TIMEZONE}" "${CHINA_ARGUMENTS}" "${Y_ARGUMENTS}"
    if [[ $? != 0 ]]; then
        error "安装 ELRepo RPM repository 失败"
        exit 1
    fi
}

########################################
# Configure kernel boot.
# Arguments:
#     None
########################################
function configure_kernel_boot() {
    color blue "========================================"
    info "配置内核启动项中..."

    local GRUB_DEFAULT=$(grep "GRUB_DEFAULT" "${BOOT_GRUB_DEFAULT_FILE}" | awk -F'=' '{ print $2 }')

    if [[ "${GRUB_DEFAULT}" == "saved" ]]; then
        # 如果不存在先生成
        if [[ ! -f "${BOOT_GRUB_CONFIG_FILE}" ]]; then
            info "配置文件不存在，生成配置文件 ${BOOT_GRUB_CONFIG_FILE}"
            grub2-mkconfig -o "${BOOT_GRUB_CONFIG_FILE}"
        fi
        grep -P -m 1 "^menuentry" "${BOOT_GRUB_CONFIG_FILE}" | awk -F"'" '{ print $2 }' | xargs -I {} grub2-set-default {}
    else
        sed -i 's@^GRUB_DEFAULT=\(.*\)@GRUB_DEFAULT=0@' "${BOOT_GRUB_DEFAULT_FILE}"
        grub2-mkconfig -o "${BOOT_GRUB_CONFIG_FILE}"
    fi

    success "配置内核启动项完成"
}

# upgrade main
function upgrade_main() {
    color blue "========================================"
    info "升级内核中..."

    yum --enablerepo=elrepo-kernel -y install kernel-ml kernel-ml-devel kernel-ml-headers kernel-ml-tools kernel-ml-tools-libs
    if [[ $? != 0 ]]; then
        error "升级内核失败"
        exit 1
    fi

    success "升级内核完成"
}

# uninstall main
function uninstall_main() {
    color blue "========================================"
    info "卸载旧内核中..."

    rpm -e --nodeps kernel-headers
    rpm -e --nodeps kernel-tools
    rpm -e --nodeps kernel-tools-libs
    rpm -qa | grep "kernel-ml" | grep -v "$(uname -r)" | xargs -I {} yum -y remove {}
    if [[ $? != 0 ]]; then
        error "卸载旧内核失败"
        exit 1
    fi

    success "卸载旧内核完成"
}

# upgrade
function upgrade() {
    install_elrepo_repository
    check_elrepo_installed

    check_upgrade

    local READ_KERNEL_UPGRADE

    clear
    color blue "##########################################################"
    color blue "# Upgrade CentOS 7.x Kernel"
    color blue "# Author: ttionya"
    color blue "# Current Version: $(color yellow "${KERNEL_VERSION_CURRENT}")"
    color blue "# Latest Version: $(color yellow "${KERNEL_VERSION_LATEST}")"
    color blue "##########################################################"
    color none ""
    color yellow "您将升级内核到最新版本，此操作具有危险性，请不要在生产环境运行该脚本"
    color none ""
    color yellow "确认升级？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_KERNEL_UPGRADE="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n):" READ_KERNEL_UPGRADE
    fi

    if [[ "${READ_KERNEL_UPGRADE^^}" == "Y" ]]; then
        uninstall_main
        upgrade_main
        configure_kernel_boot
        ask_reboot
    else
        info "已取消内核升级"
    fi
}

# uninstall
function uninstall() {
    local READ_KERNEL_UNINSTALL

    clear
    color blue "##########################################################"
    color blue "# Uninstall Old CentOS 7.x Kernel"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "您将卸载旧版本内核，此操作具有危险性"
    color none ""
    color yellow "确认卸载？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_KERNEL_UNINSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n):" READ_KERNEL_UNINSTALL
    fi

    if [[ "${READ_KERNEL_UNINSTALL^^}" == "Y" ]]; then
        uninstall_main
    else
        info "已取消旧内核卸载"
    fi
}

# main
function main() {
    check_root
    check_os_version 7
}

# dep
function dep() {
    local FUNCTION_URL="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/functions.sh"

    for ARGS_ITEM in $*;
    do
        if [[ "${ARGS_ITEM}" == "--china" ]]; then
            CHINA_MIRROR="TRUE"
            FUNCTION_URL="https://gitee.com/ttionya/Personal-VPS-Shell/raw/master/functions.sh"
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
#
# v3.0.0
#
# - 重构脚本
