#!/usr/bin/env bash

# Version: 1.0.1
# Author: ttionya
# https://dev.mysql.com/doc/mysql-yum-repo-quick-guide/en/
# https://juejin.im/post/5b6eec2cf265da0f5e3315a6


################### Customer Setting ####################
# MySQL 80 Repo 版本
LATEST_MYSQL80_REPO_VERSION="3"
# 数据库地址，路径最后不要加上斜杠 /
DATA_PATH="/data/mysql"
# 中国服务器
CHINA_SERVER=0


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

# Check System Information
function check_system_info() {
    # Check root User
    if [[ ${EUID} != 0 ]]; then
        color red "错误：该脚本必须以 root 身份运行"
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
    if [[ ${SYSTEM_VERSION} != 7 ]]; then
        color red "错误：该脚本仅支持 CentOS 7.X 版本"
        exit 1
    fi
}

# Get Software Version Information
function get_version_info() {
    color ""
    color blue "正在获取软件信息..."
    color ""

    yum clean all
    yum makecache fast

    # Get Latest MySQL Version
    LATEST_MYSQL_VERSION=$(yum list --enablerepo=mysql80-community | grep mysql-community-server.x86_64 | awk 'END {print $2}')

    if [[ -z ${LATEST_MYSQL_VERSION} ]]; then
        color ""
        color red "错误：获取 MySQL Community 8.0 最新版本失败"
        exit 1
    fi
}

# Install MySQL 80 Repo
function install_mysql80_repo() {
    yum -y install yum-utils

    rpm -Uvh --force https://repo.mysql.com//mysql80-community-release-el7-${LATEST_MYSQL80_REPO_VERSION}.noarch.rpm
    if [[ $? != 0 ]]; then
        color ""
        color red "MySQL Community 8.0 Repo 安装失败"
        exit 1
    fi
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
    yum-config-manager --disable mysql80-community

    # China Server
    if [[ ${CHINA_SERVER} == 1 ]]; then
        sed -i 's@^baseurl=http://repo.mysql.com/yum/mysql-8.0-community.*@baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql80-community-el7/@' /etc/yum.repos.d/mysql-community.repo
    fi

    # Result
    color ""
    color green "===================== MySQL Community 8.0 Repo 安装完成 ====================="
    color ""
}

# Check MySQL 80 Repo
function check_mysql80_repo() {
    color ""

    yum clean all
    yum makecache fast

    IS_INSTALLED_MYSQL80_REPO=$(yum list installed | grep -c mysql80-community-release.noarch)

    if [[ ${IS_INSTALLED_MYSQL80_REPO} == 1 ]]; then
        color yellow "重新安装 MySQL Community 8.0 Repo？ (y/n)"
        read -p "(Default: n):" CHECK_REINSTALL_REPO

        # Check Reinstall
        if [[ $(echo ${CHECK_REINSTALL_REPO:-n} | tr [a-z] [A-Z]) == Y ]]; then
            NEED_INSTALL_REPO=1
        else
            NEED_INSTALL_REPO=0
        fi
    else
        NEED_INSTALL_REPO=1
    fi

    if [[ ${NEED_INSTALL_REPO} == 1 ]]; then
        install_mysql80_repo
    else
        color ""
        color yellow "跳过 MySQL Community 8.0 Repo 安装..."
    fi
}

# Disable SELinux
function disable_selinux() {
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0

    color green "SELinux 已成功关闭"
}

# Install MySQL
function install_mysql() {
    color ""

    # Stop
    systemctl stop mysqld.service

    # Install
    yum -y --enablerepo=mysql80-community install mysql-community-server
    if [[ $? != 0 ]]; then
        if [[ $(yum list installed | grep -c mysql-community-server.x86_64) != 0 ]]; then
            systemctl restart mysqld.service
        fi

        color ""
        color red "错误：MySQL 安装失败"
        exit 1
    fi

    # Result
    color ""
    color green "===================== MySQL 安装完成 ====================="
    color ""
}

# Configure MySQL
function configure_mysql() {
    mkdir -p ${DATA_PATH}
    chown -R mysql:mysql ${DATA_PATH}

    cat > /etc/my.cnf << EOF
[client]
#password = your_password
port = 3306
socket = /var/lib/mysql/mysql.sock

[mysqld]
port = 3306
socket = /var/lib/mysql/mysql.sock
datadir = ${DATA_PATH}
pid-file = /var/run/mysqld/mysqld.pid
log-error = /var/log/mysqld.log

key_buffer_size = 16M
sort_buffer_size = 512K
net_buffer_length = 16K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
max_connections = 400
max_connect_errors = 1000
max_allowed_packet = 128M

server-id = 1
character-set-server = utf8mb4
# 针对 MyISAM 数据表，单服务器建议开启，多服务器不开启
skip-external-locking
skip-name-resolve
skip-networking

[mysql]
no-auto-rehash
EOF

    # Log Rotate
    sed -i '/^#\/var\/log/,/}/s/^#//' /etc/logrotate.d/mysql

    systemctl start mysqld.service

    color ""
    color yellow "root 密码为: $(grep 'temporary password' /var/log/mysqld.log | tail -n 1 | awk '{print $NF}')"

    # Result
    color ""
    color green "===================== MySQL 配置完成 ====================="
    color ""
}

# Check Configure MySQL
function check_configure_mysql() {
    color ""

    if [[ -f /etc/my.cnf ]]; then
        color yellow "重新配置 MySQL Community 8.0？ (y/n)"
        read -p "(Default: n):" CHECK_RECONFIGURE_MYSQL

        # Check Reconfigure
        if [[ $(echo ${CHECK_RECONFIGURE_MYSQL:-n} | tr [a-z] [A-Z]) == Y ]]; then
            NEED_CONFIGURE_MYSQL=1
        else
            NEED_CONFIGURE_MYSQL=0
        fi
    else
        NEED_CONFIGURE_MYSQL=1
    fi

    if [[ ${NEED_CONFIGURE_MYSQL} == 1 ]]; then
        configure_mysql
    else
        color ""
        color yellow "跳过 MySQL Community 8.0 配置..."
    fi
}

# Main
function main() {
    color ""
    color blue "===================== MySQL Community 8.0 安装程序启动 ====================="

    disable_selinux

    install_mysql
    check_configure_mysql

    color ""
    color green "===================== MySQL Community 8.0 安装程序已完成 ====================="
    color ""
}


################### Start ####################
check_system_info
check_mysql80_repo
get_version_info

# Show Install Information
clear
color blue "##########################################################"
color blue "# Auto Install Script for MySQL Community 8.0            #"
color blue "# Author: ttionya                                        #"
color blue "##########################################################"
color ""
color yellow "将安装 MySQL Community ${LATEST_MYSQL_VERSION}"
color ""
color yellow "继续安装将关闭 SELinux"
color ""
color x "是否安装 ？ (y/n)"
read -p "(Default: n):" CHECK_INSTALL

# Check Install
if [[ $(echo ${CHECK_INSTALL:-n} | tr [a-z] [A-Z]) == Y ]]; then
    main
else
    color ""
    color blue "MySQL Community 8.0 安装被取消..."
fi
################### End ####################

# 修改密码
# ALTER USER 'root'@'localhost' IDENTIFIED BY 'news_password';
# ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'news_password';

# Ver1.0.1
# - 修复读取最新版本读取错误的问题
