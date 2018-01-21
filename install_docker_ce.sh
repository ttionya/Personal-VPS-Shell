#!/bin/bash

# Version: 1.0.1
# Author: ttionya
# https://docs.docker.com/engine/installation/linux/docker-ce/centos/


################### Custom Setting ####################
# Docker 用户，不存在会自动创建
Docker_User="docker"

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
    echo "===================== Docker CE 安装程序 启动 ===================="

    # Uninstall Old Version of Docker
    yum remove -y docker docker-common docker-selinux docker-engine

    # Install Dependencies
    yum install -y yum-utils device-mapper-persistent-data lvm2

    # Set Docker CE Repo
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sed -i '1,/baseurl=\.*/{s@baseurl=\(.*\)@baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/$basearch/stable@}' /etc/yum.repos.d/docker-ce.repo
    sed -i '1,/gpgkey=\.*/{s@gpgkey=\(.*\)@gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg@}' /etc/yum.repos.d/docker-ce.repo

    # Install Docker CE
    yum clean all
    yum makecache fast
    yum install -y docker-ce

    # Create User And Group
    groupadd -f docker
    if id -u $Docker_User > /dev/null 2>&1; then
        if [ `id -u $Docker_User` != 0 ]; then
            usermod -aG docker $Docker_User
        fi
    else
        useradd -g docker -s /bin/bash $Docker_User
    fi

    # Auto Run
    systemctl enable docker
    systemctl start docker
    echo "===================== Docker CE 安装配置完成 ===================="
    echo ""
    echo -e "\E[1;33m如有问题，请重启\E[0m"
}


# Show Install Information
clear
echo "##########################################################"
echo "# Auto Install Script for Docker CE                      #"
echo "# Author: ttionya                                        #"
echo "##########################################################"
echo ""
echo "将安装 Docker CE"
echo ""
echo "是否安装？ (y/n)"
read -p "(Default: n):" Check_Install
if [ -z $Check_Install ]; then
    Check_Install="n"
fi

# Check Install
if [[ $Check_Install == y || $Check_Install == Y ]]; then
    main
else
    echo ""
    echo "Docker CE 安装被取消，未作任何更改..."
    echo ""
fi

# Ver1.0.1
# 自动添加 docker 组和用户