#!/bin/bash

# Version: 1.0.0
# Author: ttionya
# https://dev.mysql.com/doc/mysql-yum-repo-quick-guide/en/


################### Customer Setting ####################
# MySQL 57 Repo 版本
Latest_MySQL57_Repo_Ver="11"
# 数据库地址，路径最后不要加上斜杠 /
Data_Path="/data/mysql"
# 中国服务器
In_China=0

################### Check Info Start ####################
# Check root User
if [ $EUID != 0 ]; then
   echo -e "\033[31m错误：该脚本必须以 root 身份运行\033[0m"
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
    echo -e "\033[31m错误：该脚本仅支持 CentOS 7.X 版本\033[0m"
    exit 1
fi
################### Check Info End ####################

# Install MySQL 57 Repo Function
function install_mysql57_repo() {
    echo ""
    echo -e "\033[33m===================== 开始安装 MySQL 57 Repo ====================\033[0m"

    yum -y install yum-utils

    rpm -Uvh --force https://dev.mysql.com/get/mysql57-community-release-el7-$Latest_MySQL57_Repo_Ver.noarch.rpm
    if [ $? != 0 ]; then
        echo -e "\033[31mMySQL 57 Repo 安装失败\033[0m"
        exit 1
    fi
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql
    yum-config-manager --disable mysql57-community

    # China
    if [[ $In_China == 1 ]]; then
        sed -i 's@^baseurl=http://repo.mysql.com/yum/mysql-5.7-community.*@baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql57-community-el7/@' /etc/yum.repos.d/mysql-community.repo
    fi
}

# Check Install MySQL 57 Repo Function
function check_install_mysql57_repo() {
    # Show Install Information
    clear
    echo -e "\033[34m##########################################################\033[0m"
    echo -e "\033[34m# Install CentOS 7.X MySQL 57 Repository                 #\033[0m"
    echo -e "\033[34m# Author: ttionya                                        #\033[0m"
    echo -e "\033[34m##########################################################\033[0m"
    echo ""
    echo -e "\033[33m需要安装 MySQL 57 仓库\033[0m"
    echo ""
    echo "安装 MySQL 57 仓库？ (y/n)"
    read -p "(Default: n):" Check_Install
    if [ -z $Check_Install ]; then
        Check_Install="n"
    fi

    # Check Install
    if [[ $Check_Install == y || $Check_Install == Y ]]; then
        install_mysql57_repo
    else
        echo ""
        echo -e "\033[34mMySQL 安装被取消，未作任何更改...\033[0m"
        exit 0
    fi
}

# Install MySQL Function
function install_mysql() {
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
    echo -e "\033[32mSELinux 已成功关闭\033[0m"

    echo ""
    echo -e "\033[33m===================== 开始安装 MySQL 57 ====================\033[0m"

    # Remove
    rpm -e --nodeps mysql
    yum -y remove mysql
    systemctl stop mysqld

    # Install
    yum -y --enablerepo=mysql57-community install mysql-community-server
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：MySQL 安装失败\033[0m"
        exit 1
    fi

    echo -e "\033[32m===================== MySQL 安装完成，开始进行配置 ====================\033[0m"

    # Configure
    mkdir -p $Data_Path
    chown -R mysql:mysql $Data_Path
    cat > /etc/my.cnf << EOF
[client]
#password = your_password
port = 3306
socket = /var/lib/mysql/mysql.sock

[mysqld]
port = 3306
socket = /var/lib/mysql/mysql.sock
datadir = $Data_Path
pid-file = /var/run/mysqld/mysqld.pid
log-error = /var/log/mysqld.log
character-set-server = utf8mb4

key_buffer_size = 16M
sort_buffer_size = 512K
net_buffer_length = 8K
read_buffer_size = 256K
read_rnd_buffer_size = 512K
myisam_sort_buffer_size = 8M
query_cache_size = 64M
query_cache_limit = 4M
table_open_cache = 64
max_connections = 1000
max_allowed_packet = 16M

server-id = 1
symbolic-links = 0
skip-external-locking
skip-name-resolve
skip-networking

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer_size = 2M
write_buffer_size = 2M
EOF

    echo ""
    echo -e "\033[32mMySQL 配置完成\033[0m"

    systemctl start mysqld.service

    sed -i '/^#\/var\/log/,/}/s/^#//' /etc/logrotate.d/mysql
    echo -e "\033[32mMySQL logrotate 设置完成\033[0m"

    echo ""
    echo -e "\033[33mroot 密码为：`grep 'temporary password' /var/log/mysqld.log | tail -n 1 | awk '{print $NF}'`\033[0m"
}

# Check Install MySQL Function
function check_install_mysql() {
    yum clean all
    yum makecache fast

    # Check Latest MySQL Version
    Latest_MySQL_Ver=`yum list | grep mysql-community-server.x86_64 | awk '{print $2}'`

    # Show Install Information
    clear
    echo -e "\033[34m##########################################################\033[0m"
    echo -e "\033[34m# Auto Install Script for MySQL Community 5.7            #\033[0m"
    echo -e "\033[34m# System Required:  CentOS / RedHat 7.X                  #\033[0m"
    echo -e "\033[34m# Author: ttionya                                        #\033[0m"
    echo -e "\033[34m##########################################################\033[0m"
    echo ""
    echo -e "\033[33m将安装 MySQL Community $Latest_MySQL_Ver\033[0m"
    echo ""
    echo -e "\033[33m继续安装将关闭 SELinux\033[0m"
    echo ""
    echo "是否安装？ (y/n)"
    read -p "(Default: n):" Check_Install
    if [ -z $Check_Install ]; then
        Check_Install="n"
    fi

    # Check Install
    if [[ $Check_Install == y || $Check_Install == Y ]]; then
        install_mysql
    else
        echo ""
        echo -e "\033[34mMySQL 安装被取消，未作任何更改...\033[0m"
    fi
}

# Check MySQL 57 Repo
Is_Installed_MySQL57_Repo=`yum list installed | grep -c mysql57-community`

if [[ $Is_Installed_MySQL57_Repo == 1 ]]; then
    check_install_mysql
else
    check_install_mysql57_repo
    check_install_mysql
fi

# 编译参数
# cmake \
# -DCMAKE_INSTALL_PREFIX=$Install_MySQL_Path \
# -DSYSCONFDIR=/etc \
# -DMYSQL_UNIX_ADDR=/var/run/mysql.sock \
# -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
# -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
# -DWITH_FEDERATED_STORAGE_ENGINE=1 \
# -DWITH_PARTITION_STORAGE_ENGINE=1 \
# -DDEFAULT_CHARSET=utf8mb4 \
# -DDEFAULT_COLLATION=utf8mb4_general_ci \
# -DWITH_EXTRA_CHARSETS=all \
# -DWITH_BOOST=./boost \
# -DENABLED_LOCAL_INFILE=1

# 修改密码
# ALTER USER USER() IDENTIFIED BY 'news_password';