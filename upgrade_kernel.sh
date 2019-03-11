#!/bin/bash

# Version: 1.3.1
# Author: ttionya


################### Customer Setting ####################
# 中国服务器
In_China=0

################### Function ####################
function color() {
    case $1 in
        red)
            echo -e "\033[31m$2\033[0m"
            ;;
        green)
            echo -e "\033[32m$2\033[0m"
            ;;
        yellow)
            echo -e "\033[33m$2\033[0m"
            ;;
        blue)
            echo -e "\033[34m$2\033[0m"
            ;;
        *)
            echo $2
    esac
}

################### Check Info Start ####################
# Check root User
if [[ ${EUID} != 0 ]]; then
   color red "错误：该脚本必须以 root 身份运行"
   exit 1
fi

# Check CentOS Version
# CentOS 7.X Only
if [[ -s /etc/redhat-release ]]; then
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/redhat-release`
else
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/issue`
fi
CentOS_Ver=${CentOS_Ver%%.*}
if [[ ${CentOS_Ver} != 7 ]]; then
    color red "错误：该脚本仅支持 CentOS 7.X 版本"
    exit 1
fi
################### Check Info End ####################

# Upgrade Kernel Function
function upgrade_kernel() {
    color ""
    color yellow "==================== 开始升级内核 ===================="

    # 移除旧内核
    rpm -e --nodeps kernel-headers
    rpm -e --nodeps kernel-tools
    rpm -e --nodeps kernel-tools-libs
    rpm -qa | grep kernel-ml | grep -v `uname -r` | xargs -I {} yum remove -y {}

    # 安装
    yum --enablerepo=elrepo-kernel -y install kernel-ml kernel-ml-devel kernel-ml-headers kernel-ml-tools kernel-ml-tools-libs

    # 设置启动项
    GrubDefault=`grep GRUB_DEFAULT /etc/default/grub | awk -F "=" '{print $2}'`
    if [[ ${GrubDefault} == saved ]]; then
        # 如果不存在先生成
        if [[ ! -f /boot/grub2/grub.cfg ]]; then
            grub2-mkconfig -o /boot/grub2/grub.cfg
        fi
        grep -P -m 1 "^menuentry" /boot/grub2/grub.cfg | awk -F "'" '{print $2}' | xargs -I {} grub2-set-default {}
    else
        sed -i 's@^GRUB_DEFAULT=\(.*\)@GRUB_DEFAULT=0@' /etc/default/grub
        grub2-mkconfig -o /boot/grub2/grub.cfg
    fi

    color ""
    color green "==================== 内核安装完成，按 Y 立即重启 ===================="
    read -p "(Default: n):" Check_Reboot
    if [[ -z ${Check_Reboot} ]]; then
        Check_Reboot="n"
    fi

    # Check Update
    if [[ ${Check_Reboot} == y || ${Check_Reboot} == Y ]]; then
        reboot
    else
        color ""
        color yellow "请手动重启系统"
        color ""
    fi
}

# Check Upgrade Kernel Function
function check_upgrade_kernel() {
    yum clean all
    yum makecache fast

    # Check Current Kernel Version
    Current_Kernel_Version=`uname -r`
    Newest_Kernel_Version=`yum --enablerepo=elrepo-kernel list | grep -P '[^@]elrepo-kernel' | grep kernel-ml.x86_64 | awk -F" " '{print $2}'`

    # 最新版无需升级
    if [[ -z ${Newest_Kernel_Version} ]]; then
        color ""
        color yellow "您的内核 ${Current_Kernel_Version} 已是最新版，无需升级"
        exit 0
    fi

    # Show Upgrade Information
    clear
    color blue "##########################################################"
    color blue "# Upgrade CentOS 7.X Kernel"
    color blue "# Author: ttionya"
    color blue "# Current Kernel: $(color yellow ${Current_Kernel_Version})"
    color blue "# Newest Kernel: $(color yellow ${Newest_Kernel_Version})"
    color blue "##########################################################"
    color ""
    color yellow "您将升级内核到最新版本，此操作具有危险性，请不要在生产环境运行该脚本"
    color ""
    color x "继续升级内核？ (y/n)"
    read -p "(Default: n):" Check_Update
    if [[ -z ${Check_Update} ]]; then
        Check_Update="n"
    fi

    # Check Update
    if [[ ${Check_Update} == y || ${Check_Update} == Y ]]; then
        upgrade_kernel
    else
        color ""
        color blue "内核升级被取消，未作任何更改..."
        color ""
    fi
}

# Install ELRepo
curl https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/repo_elrepo.sh | bash -s -- ${In_China}

# Check Information
check_upgrade_kernel

# Ver1.0.1
# - 修改脚本内容
#
# Ver1.0.2
# - 修复某些 VPS 上升级内核导致无法开机的问题
#
# Ver1.1.0
# - 优化升级脚本
#
# Ver1.1.1
# - 命名脚本版本
#
# Ver1.1.2
# - 优化获取最新版 kernel-ml 版本方式
#
# Ver1.1.3
# - 最新版本不会执行升级操作
# - 优化旧版本删除逻辑
#
# Ver1.2.0
# - 支持设定服务器地址，设置为国内则自动将 ElRepo 设置为清华源
#
# Ver1.2.1
# - 修复 kernel-header 未安装时导致升级失败的问题
#
# Ver1.2.2
# - 修复无法终止脚本的错误
# - 添加更多颜色支持
#
# Ver1.3.0
# - 拆分 ELRepo 安装程序
# - 优化脚本
#
# Ver1.3.1
# - 修复 GRUB 配置文件不存在导致配置失败的问题
