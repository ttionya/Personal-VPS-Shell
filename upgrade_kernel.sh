#!/bin/bash

# Version: 1.2.0
# Author: ttionya


################### Customer Setting ####################
# elrepo 版本
ElRepo_Ver="7.0-3"
# 中国服务器
In_China=0

################### Check Info Start ####################
# Check root User
if [ $EUID != 0 ]; then
   echo "错误：该脚本必须以 root 身份运行"
   exit 1
fi

# Check CentOS Version
# CentOS 7.X Only
if [ -s /etc/redhat-release ]; then
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/redhat-release`
else
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/issue`
fi
CentOS_Ver=${CentOS_Ver%%.*}
if [ $CentOS_Ver != 7 ]; then
    echo "错误：该脚本仅支持 CentOS 7.X 版本"
    exit 1
fi
################### Check Info End ####################

# Install Elrepo Function
function install_elrepo() {
    echo ""
    echo "===================== 开始安装 Elrepo ===================="

    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh --force http://www.elrepo.org/elrepo-release-$ElRepo_Ver.el7.elrepo.noarch.rpm
    if [ $? != 0 ]; then
        echo "Elrepo 安装失败"
        exit 1
    fi

    # China
    if [[ $In_China == 1 ]]; then
        sed -i 's@^baseurl=.*\.org/linux/\(.*\)@baseurl=https://mirrors.tuna.tsinghua.edu.cn/elrepo/\1@' /etc/yum.repos.d/elrepo.repo
        sed -i 's@^\(\thttp.*\)@#\1@' /etc/yum.repos.d/elrepo.repo
        sed -i 's@^mirrorlist=\(.*\)@#mirrorlist=\1@' /etc/yum.repos.d/elrepo.repo
    fi
}

# Check Install Elrepo Function
function check_install_elrepo() {
    # Show Install Information
    clear
    echo "##########################################################"
    echo "# Install CentOS 7.X Elrepo Repository                   #"
    echo "# Author: ttionya                                        #"
    echo "##########################################################"
    echo ""
    echo "升级内核需要安装 elrepo 仓库"
    echo ""
    echo "安装 elrepo 仓库？ (y/n)"
    read -p "(Default: n):" Check_Install
    if [ -z $Check_Install ]; then
        Check_Install="n"
    fi

    # Check Install
    if [[ $Check_Install == y || $Check_Install == Y ]]; then
        install_elrepo
    else
        echo ""
        echo "内核升级被取消，未作任何更改..."
        echo ""
    fi
}

# Upgrade Kernel Function
function upgrade_kernel() {
    echo ""
    echo "===================== 开始升级内核 ===================="

    # 移除旧内核
    rpm -e --nodeps kernel-headers kernel-tools kernel-tools-libs
    rpm -qa | grep kernel-ml | grep -v `uname -r` | xargs -I {} yum remove -y {}

    # 安装
    yum --enablerepo=elrepo-kernel -y install kernel-ml kernel-ml-devel kernel-ml-headers kernel-ml-tools kernel-ml-tools-libs

    # 设置启动项
    grubDefault=`cat /etc/default/grub | grep GRUB_DEFAULT | awk -F "=" '{print $2}'`
    if [[ $grubDefault == saved ]]; then
        cat /boot/grub2/grub.cfg | grep -P "^menuentry" | awk -F "'" '{print $2}' | head -n 1 | xargs -I {} grub2-set-default {}
    else
        sed -i 's@^GRUB_DEFAULT=\(.*\)@GRUB_DEFAULT=0@' /etc/default/grub
        grub2-mkconfig -o /boot/grub2/grub.cfg
    fi

    echo "===================== 内核安装完成，按 Y 立即重启 ===================="
    read -p "(Default: n):" Check_Reboot
    if [ -z $Check_Reboot ]; then
        Check_Reboot="n"
    fi

    # Check Update
    if [[ $Check_Reboot == y || $Check_Reboot == Y ]]; then
        reboot
    else
        echo ""
        echo "请手动重启系统"
        echo ""
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
    if [ -z $Newest_Kernel_Version ]; then
        echo ""
        echo -e "\E[1;33m您的内核 $Current_Kernel_Version 已是最新版，无需升级\E[0m"
        echo ""
        exit 0
    fi

    # Show Upgrade Information
    clear
    echo "##########################################################"
    echo "# Upgrade CentOS 7.X Kernel"
    echo "# Author: ttionya"
    echo -e "# Current Kernel: \E[1;33m$Current_Kernel_Version\E[0m"
    echo -e "# Newest Kernel: \E[1;33m$Newest_Kernel_Version\E[0m"
    echo "##########################################################"
    echo ""
    echo "您将升级内核到最新版本，此操作具有危险性，请不要在生产环境运行该脚本"
    echo ""
    echo "继续升级内核？ (y/n)"
    read -p "(Default: n):" Check_Update
    if [ -z $Check_Update ]; then
        Check_Update="n"
    fi

    # Check Update
    if [[ $Check_Update == y || $Check_Update == Y ]]; then
        upgrade_kernel
    else
        echo ""
        echo "内核升级被取消，未作任何更改..."
        echo ""
    fi
}

# Check Elrepo
Is_Installed_Elrepo=`yum list installed | grep elrepo-release | wc -l`

if [[ $Is_Installed_Elrepo == 1 ]]; then
    check_upgrade_kernel
else
    check_install_elrepo
    check_upgrade_kernel
fi

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