#!/bin/bash

# Version: 1.0.1
# Author: ttionya


################### Customer Setting ####################
# elrepo 版本
ElRepo_Ver="7.0-3"

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


# Main Function
function main() {
    echo ""
    echo "===================== 开始升级内核 ===================="

    # 安装 ElRepo
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh --force http://www.elrepo.org/elrepo-release-$ElRepo_Ver.el7.elrepo.noarch.rpm
    sed -i 's@^baseurl=.*\.org/linux/\(.*\)@baseurl=https://mirrors.tuna.tsinghua.edu.cn/elrepo/\1@' /etc/yum.repos.d/elrepo.repo
    sed -i 's@^\(\thttp.*\)@#\1@' /etc/yum.repos.d/elrepo.repo
    sed -i 's@^mirrorlist=\(.*\)@#mirrorlist=\1@' /etc/yum.repos.d/elrepo.repo

    # 移除旧内核
    rpm -e --nodeps kernel-ml-devel kernel-headers kernel-tools kernel-tools-libs
    yum --enablerepo=elrepo-kernel -y install kernel-ml kernel-ml-devel kernel-ml-headers kernel-ml-tools kernel-ml-tools-libs

    # 设置启动项
    sed -i 's@^GRUB_DEFAULT=\(.*\)@GRUB_DEFAULT=0@' /etc/default/grub
    grub2-mkconfig -o /boot/grub2/grub.cfg

    echo "===================== 内核安装完成，5秒后自动重启 ===================="
    echo "5"
    sleep 1
    echo "4"
    sleep 1
    echo "3"
    sleep 1
    echo "2"
    sleep 1
    echo "1"
    sleep 1
    reboot
}


# Show Upgrade Information
clear
echo "##########################################################"
echo "# Upgrade CentOS 7.X Kernel                              #"
echo "# Author: ttionya                                        #"
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
    main
else
    echo ""
    echo "内核升级被取消，未作任何更改..."
    echo ""
fi

# Ver1.0.1
# - 修改脚本内容