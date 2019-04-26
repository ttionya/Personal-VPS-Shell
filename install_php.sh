#!/usr/bin/env bash

# Version: 2.0.0
# Author: ttionya


################### Customer Setting ####################
# 下载地址
DOWNLOAD_PATH="/usr/local/src"
# 低权限用户和组
LOW_LEVEL_USER="www"
LOW_LEVEL_GROUP="www"
# 默认网站路径
WWW_PATH="/data/www"
# PCRE 2 版本号
LATEST_PCRE2_VERSION="10.33"
# re2c 版本号
LATEST_RE2C_VERSION="1.1.1"
# libzip 版本号，1.3.2 是不需要高版本 CMAKE 的最后版本
LATEST_LIBZIP_VERSION="1.3.2"
# PHP 版本号
LATEST_PHP_VERSION="7.3.4"
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# Apache 安装路径
INSTALL_APACHE_PATH="/usr/local/apache"
# PHP 安装路径
INSTALL_PHP_PATH="/usr/local/php"
# PCRE 2 安装路径
INSTALL_PCRE2_PATH="/usr/local/pcre2"


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

# Check Installed Software Information
function check_installed_info() {
    # Check PHP Path
    if [[ -d ${INSTALL_PHP_PATH} ]]; then
        color yellow "警告：PHP 目录 ${INSTALL_PHP_PATH} 已存在"
        color yellow "继续下一步会立即删除已存在的目录，是否要继续 ？ (y/n)"
        read -p "(Default: n):" CHECK_DEL_INSTALLED

        # Check Delete Installed Path
        if [[ $(echo ${CHECK_DEL_INSTALLED:-n} | tr [a-z] [A-Z]) == Y ]]; then
            pkill -9 php-fpm
            rm -rf ${INSTALL_PHP_PATH}
            color green "删除成功"
        else
            color ""
            color blue "PHP 安装被取消..."
            exit 0
        fi
    fi
}

# Get Software Version Information
function get_version_info() {
    color ""
    color blue "正在获取软件信息..."
    color ""

    # Get Ram Information
    MAM="$(free -m | awk '{a+=$2} END {print a}')"
    if [[ ${MAM} -lt 1000 ]]; then
        CONFIGURE_FILE_INFO="--disable-fileinfo"
        CONFIGURE_FILE_INFO_MSG="内存不足，已禁用 fileinfo 编译选项"
    else
        CONFIGURE_FILE_INFO=""
        CONFIGURE_FILE_INFO_MSG="未禁用 fileinfo 编译选项"
    fi

    # Check CPU Number
    CPU_NUM=$(grep -c 'processor' /proc/cpuinfo)
}

# Remove YUM Version PHP
function remove_yum_php() {
    rpm -e --nodeps php
    yum -y remove php
}

# Install Dependencies
function install_dependencies() {
    curl https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/lamp_devel.sh | bash -
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：依赖安装失败"
        exit 1
    fi
}

# Install re2c
function install_re2c() {
    color ""
    cd ${DOWNLOAD_PATH}

    DIR_SOURCE_RE2C="re2c-${LATEST_RE2C_VERSION}"
    FILE_SOURCE_RE2C="re2c-${LATEST_RE2C_VERSION}.tar.gz"

    # Clean UP
    rm -rf ${DIR_SOURCE_RE2C}

    # Download
    if [[ ! -s ${FILE_SOURCE_RE2C} ]]; then
        wget -c -t3 -T60 "https://github.com/skvadrik/re2c/releases/download/${LATEST_RE2C_VERSION}/${FILE_SOURCE_RE2C}" -O ${FILE_SOURCE_RE2C}
        if [[ $? != 0 ]]; then
            rm -rf ${FILE_SOURCE_RE2C}
            color ""
            color red "错误：re2c 下载失败"
            exit 1
        fi
    fi

    # Extract
    tar -zxf ${FILE_SOURCE_RE2C}
    cd ${DIR_SOURCE_RE2C}

    # Configure
    ./configure
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：re2c 配置失败"
        exit 1
    fi

    # Make
    make -j ${CPU_NUM}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：re2c 编译失败"
        exit 1
    fi

    # Install
    make install
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：re2c 安装失败"
        exit 1
    fi

    # Clean Up
    cd ${DOWNLOAD_PATH}
    rm -rf ${DIR_SOURCE_RE2C}

    # Result
    color ""
    color green "===================== re2c 安装完成 ====================="
    color ""
}

# Check re2c
function check_re2c() {
    color ""
    BIN_RE2C="re2c"

    if which ${BIN_RE2C} > /dev/null 2>&1; then
        INSTALLED_RE2C_VERSION="$(${BIN_RE2C} -v | awk '{print $2}')"

        color yellow "re2c ${INSTALLED_RE2C_VERSION} -> re2c ${LATEST_RE2C_VERSION}，确认安装？ (y/n)"
        read -p "(Default: y):" CHECK_REINSTALL_RE2C

        # Check Reinstall
        if [[ $(echo ${CHECK_REINSTALL_RE2C:-y} | tr [a-z] [A-Z]) == Y ]]; then
            NEED_INSTALL_RE2C=1
        else
            NEED_INSTALL_RE2C=0
        fi
    else
        NEED_INSTALL_RE2C=1
    fi

    if [[ ${NEED_INSTALL_RE2C} == 1 ]]; then
        install_re2c
    else
        color ""
        color yellow "跳过 re2c ${LATEST_RE2C_VERSION} 安装..."
    fi
}

# Install PCRE2
function install_pcre2() {
    color ""
    cd ${DOWNLOAD_PATH}

    DIR_SOURCE_PCRE2="pcre2-${LATEST_PCRE2_VERSION}"
    FILE_SOURCE_PCRE2="pcre2-${LATEST_PCRE2_VERSION}.tar.gz"

    # Clean UP
    rm -rf ${DIR_SOURCE_PCRE2}

    # Download
    if [[ ! -s ${FILE_SOURCE_PCRE2} ]]; then
        wget -c -t3 -T60 "https://ftp.pcre.org/pub/pcre/${FILE_SOURCE_PCRE2}"
        if [[ $? != 0 ]]; then
            rm -rf ${FILE_SOURCE_PCRE2}
            color ""
            color red "错误：PCRE 2 下载失败"
            exit 1
        fi
    fi

    # Extract
    tar -zxf ${FILE_SOURCE_PCRE2}
    cd ${DIR_SOURCE_PCRE2}

    # Configure
    ./configure --prefix=${INSTALL_PCRE2_PATH}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：PCRE 2 配置失败"
        exit 1
    fi

    # Make
    make -j ${CPU_NUM}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：PCRE 2 编译失败"
        exit 1
    fi

    # Backup
    if [[ -d ${INSTALL_PCRE2_PATH} ]]; then
        rm -rf ${INSTALL_PCRE2_PATH}.bak
        mv ${INSTALL_PCRE2_PATH} ${INSTALL_PCRE2_PATH}.bak
    fi

    # Install
    make install
    if [[ $? != 0 ]]; then
        rm -rf ${INSTALL_PCRE2_PATH}
        mv ${INSTALL_PCRE2_PATH}.bak ${INSTALL_PCRE2_PATH}
        color ""
        color red "错误：PCRE 2 安装失败"
        exit 1
    fi

    # Clean Up
    cd ${DOWNLOAD_PATH}
    rm -rf ${DIR_SOURCE_PCRE2}

    # Result
    color ""
    color green "===================== PCRE 2 安装完成 ====================="
    color ""
}

# Check PCRE2
function check_pcre2() {
    color ""
    BIN_PCRE2="${INSTALL_PCRE2_PATH}/bin/pcre2-config"

    if which ${BIN_PCRE2} > /dev/null 2>&1; then
        INSTALLED_PCRE2_VERSION="$(${BIN_PCRE2} --version)"

        color yellow "PCRE 2 ${INSTALLED_PCRE2_VERSION} -> PCRE 2 ${LATEST_PCRE2_VERSION}，确认安装？ (y/n)"
        read -p "(Default: y):" CHECK_REINSTALL_PCRE2

        # Check Reinstall
        if [[ $(echo ${CHECK_REINSTALL_PCRE2:-y} | tr [a-z] [A-Z]) == Y ]]; then
            NEED_INSTALL_PCRE2=1
        else
            NEED_INSTALL_PCRE2=0
        fi
    else
        NEED_INSTALL_PCRE2=1
    fi

    if [[ ${NEED_INSTALL_PCRE2} == 1 ]]; then
        install_pcre2
    else
        color ""
        color yellow "跳过 PCRE 2 ${LATEST_PCRE2_VERSION} 安装..."
    fi
}

# Install libzip
# http://bbs.itzmx.com/forum.php?mod=viewthread&tid=88820
function install_libzip() {
    color ""
    cd ${DOWNLOAD_PATH}

    DIR_SOURCE_LIBZIP="libzip-${LATEST_LIBZIP_VERSION}"
    FILE_SOURCE_LIBZIP="libzip-${LATEST_LIBZIP_VERSION}.tar.gz"

    # Remove YUM Version libzip
    yum remove -y libzip

    # Clean UP
    rm -rf ${DIR_SOURCE_LIBZIP}

    # Download
    if [[ ! -s ${FILE_SOURCE_LIBZIP} ]]; then
        wget -c -t3 -T60 "https://libzip.org/download/${FILE_SOURCE_LIBZIP}"
        if [[ $? != 0 ]]; then
            rm -rf ${FILE_SOURCE_LIBZIP}
            color ""
            color red "错误：libzip 下载失败"
            exit 1
        fi
    fi

    # Extract
    tar -zxf ${FILE_SOURCE_LIBZIP}
    cd ${DIR_SOURCE_LIBZIP}

    # Configure
    ./configure
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：libzip 配置失败"
        exit 1
    fi

    # Make
    make -j ${CPU_NUM}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：libzip 编译失败"
        exit 1
    fi

    # Install
    make install
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：libzip 安装失败"
        exit 1
    fi

    # Add to ld Path
    echo "/usr/local/lib" > /etc/ld.so.conf.d/libzip.conf
    ldconfig -v

    # Clean Up
    cd ${DOWNLOAD_PATH}
    rm -rf ${DIR_SOURCE_LIBZIP}

    # Result
    color ""
    color green "===================== libzip 安装完成 ====================="
    color ""
}

# Check libzip
function check_libzip() {
    color ""
    BIN_LIBZIP="zipcmp"

    if which ${BIN_LIBZIP} > /dev/null 2>&1; then
        INSTALLED_LIBZIP_VERSION="$(${BIN_LIBZIP} -V | head -n 1 | grep -oP '[0-9.]*')"

        color yellow "libzip ${INSTALLED_LIBZIP_VERSION} -> libzip ${LATEST_LIBZIP_VERSION}，确认安装？ (y/n)"
        read -p "(Default: y):" CHECK_REINSTALL_LIBZIP

        # Check Reinstall
        if [[ $(echo ${CHECK_REINSTALL_LIBZIP:-y} | tr [a-z] [A-Z]) == Y ]]; then
            NEED_INSTALL_LIBZIP=1
        else
            NEED_INSTALL_LIBZIP=0
        fi
    else
        NEED_INSTALL_LIBZIP=1
    fi

    if [[ ${NEED_INSTALL_LIBZIP} == 1 ]]; then
        install_libzip
    else
        color ""
        color yellow "跳过 libzip ${LATEST_LIBZIP_VERSION} 安装..."
    fi
}

# Install PHP
function install_php() {
    color ""
    cd ${DOWNLOAD_PATH}

    DIR_SOURCE_PHP="php-${LATEST_PHP_VERSION}"
    FILE_SOURCE_PHP="php-${LATEST_PHP_VERSION}.tar.gz"

    # Clean UP
    rm -rf ${DIR_SOURCE_PHP}

    # Download
    if [[ ! -s ${FILE_SOURCE_PHP} ]]; then
        wget -c -t3 -T60 "https://www.php.net/distributions/${FILE_SOURCE_PHP}" -O ${FILE_SOURCE_PHP}
        if [[ $? != 0 ]]; then
            rm -rf ${FILE_SOURCE_PHP}

            # Retry China Mirrors
            wget -c -t3 -T60 "http://cn2.php.net/distributions/${FILE_SOURCE_PHP}" -O ${FILE_SOURCE_PHP}
            if [[ $? != 0 ]]; then
                rm -rf ${FILE_SOURCE_PHP}
                color ""
                color red "错误：PHP 下载失败"
                exit 1
            fi
        fi
    fi

    # Extract
    tar -zxf ${FILE_SOURCE_PHP}
    cd ${DIR_SOURCE_PHP}

    # Configure
    ./configure \
    --prefix=${INSTALL_PHP_PATH} \
    --with-config-file-path=${INSTALL_PHP_PATH}/etc \
    --with-libdir=lib64 \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-mysql-sock=/var/lib/mysql/mysql.sock \
    --with-pcre-dir=${INSTALL_PCRE2_PATH} \
    --with-pcre-regex \
    --with-pcre-jit \
    --with-libxml-dir=/usr \
    --with-icu-dir=/usr \
    --with-openssl \
    --enable-fpm \
    --with-fpm-user=${LOW_LEVEL_USER} \
    --with-fpm-group=${LOW_LEVEL_GROUP} \
    --with-bz2 \
    --with-curl \
    --with-freetype-dir \
    --with-jpeg-dir \
    --with-png-dir \
    --with-webp-dir \
    --with-gd \
    --with-gettext \
    --with-gmp \
    --with-ldap \
    --with-ldap-sasl \
    --with-xmlrpc \
    --with-xsl \
    --with-zlib \
    --with-kerberos \
    --without-pear \
    --enable-mysqlnd \
    --enable-bcmath \
    --enable-calendar \
    --enable-ftp \
    --enable-sysvsem \
    --enable-exif \
    --enable-intl \
    --enable-mbstring \
    --enable-pcntl \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-wddx \
    --enable-zip \
    ${CONFIGURE_FILE_INFO}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：PHP 配置失败"
        exit 1
    fi

    # Make
    make -j ${CPU_NUM}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：PHP 编译失败"
        exit 1
    fi

    # Install
    make install
    if [[ $? != 0 ]]; then
        rm -rf ${INSTALL_PHP_PATH}
        color ""
        color red "错误：PHP 安装失败"
        exit 1
    fi

    # Copy Files
    mkdir -p ${INSTALL_PHP_PATH}/etc
    cp -f php.ini-production ${INSTALL_PHP_PATH}/etc/php.ini

    # Add Systemd Script
    cp -f sapi/fpm/php-fpm.service /usr/lib/systemd/system/
    systemctl daemon-reload

    # Clean Up
    cd ${DOWNLOAD_PATH}
    rm -rf ${DIR_SOURCE_PHP}

    # Result
    color ""
    color green "===================== PHP 安装完成 ====================="
    color ""
}

# Configure PHP
function configure_php() {
    # Auto Start
    systemctl enable php-fpm.service
    if [[ $? != 0 ]]; then
        color yellow "警告：PHP-FPM 设置开机自启动失败"
    else
        color green "PHP-FPM 设置开机自启动成功"
    fi

    # Add PATH
    if [[ $(grep -c "${INSTALL_PHP_PATH}/bin/:${INSTALL_PHP_PATH}/sbin/" /etc/profile) == 0 ]]; then
        echo "" >> /etc/profile
        echo "export PATH=\${PATH}:${INSTALL_PHP_PATH}/bin/:${INSTALL_PHP_PATH}/sbin/" >> /etc/profile
        source /etc/profile
    fi

    # Link Logs
    ln -fns ${INSTALL_PHP_PATH}/var/log /var/log/php-fpm

    # Create User And Group
    groupadd -f ${LOW_LEVEL_GROUP}
    if id -u ${LOW_LEVEL_USER} > /dev/null 2>&1; then
        color yellow "用户已存在，跳过"
    else
        useradd -g ${LOW_LEVEL_GROUP} -s /sbin/nologin ${LOW_LEVEL_USER}
    fi

    # Set php.ini File
    FILE_CONF_PHP="${INSTALL_PHP_PATH}/etc/php.ini"
    cp -f ${FILE_CONF_PHP} ${FILE_CONF_PHP}.default
    # Common
    sed -i 's@^short_open_tag = Off@short_open_tag = On@' ${FILE_CONF_PHP}
    sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket,pfsockopen@' ${FILE_CONF_PHP}
    sed -i 's@^expose_php = On@expose_php = Off@' ${FILE_CONF_PHP}
    sed -i 's@^allow_url_fopen.*@allow_url_fopen = Off@' ${FILE_CONF_PHP}
    sed -i 's@^max_execution_time.*@max_execution_time = 300@' ${FILE_CONF_PHP}
    sed -i 's@^request_order.*@request_order = "CGP"@' ${FILE_CONF_PHP}
    sed -i "s@extension_dir = \"ext\"@extension_dir = \"ext\"\nextension_dir = \"${INSTALL_PHP_PATH}/lib/php/extensions/$(ls ${INSTALL_PHP_PATH}/lib/php/extensions/)\"@" ${FILE_CONF_PHP}
    color green "基本设置配置成功"
    # Upload
    sed -i 's@^;upload_tmp_dir.*@upload_tmp_dir = /tmp@' ${FILE_CONF_PHP}
    sed -i 's@^upload_max_filesize.*@upload_max_filesize = 50M@' ${FILE_CONF_PHP}
    sed -i 's@^post_max_size.*@post_max_size = 50M@' ${FILE_CONF_PHP}
    color green "上传配置成功"
    # Date
    sed -i 's@^;date.timezone.*@date.timezone = Asia/Shanghai@' ${FILE_CONF_PHP}
    color green "时区配置成功"
    # Session 模块
    sed -i 's@^session.cookie_httponly.*@session.cookie_httponly = 1@' ${FILE_CONF_PHP}
    color green "会话配置成功"
    # Opcache 模块
    sed -i 's@^\[opcache\]@[opcache]\nzend_extension=opcache.so@' ${FILE_CONF_PHP}
    sed -i 's@^;opcache.enable=.*@opcache.enable=1@' ${FILE_CONF_PHP}
    sed -i 's@^;opcache.memory_consumption.*@opcache.memory_consumption=128@' ${FILE_CONF_PHP}
    sed -i 's@^;opcache.interned_strings_buffer.*@opcache.interned_strings_buffer=8@' ${FILE_CONF_PHP}
    sed -i 's@^;opcache.max_accelerated_files.*@opcache.max_accelerated_files=10000@' ${FILE_CONF_PHP}
    sed -i 's@^;opcache.max_wasted_percentage.*@opcache.max_wasted_percentage=5@' ${FILE_CONF_PHP}
    sed -i 's@^;opcache.validate_timestamps.*@opcache.validate_timestamps=1@' ${FILE_CONF_PHP}
    sed -i 's@^;opcache.revalidate_freq.*@opcache.revalidate_freq=60@' ${FILE_CONF_PHP}
    color green "Opcache 配置成功"

    # Set php-fpm.conf File
    FILE_CONF_PHP_FPM="${INSTALL_PHP_PATH}/etc/php-fpm.conf"
    cp -f ${FILE_CONF_PHP_FPM}.default ${FILE_CONF_PHP_FPM}
    sed -i 's@^;pid =\(.*\)@pid =\1@' ${FILE_CONF_PHP_FPM}
    sed -i 's@^;error_log =\(.*\)@error_log =\1@' ${FILE_CONF_PHP_FPM}
    sed -i 's@^;log_level =.*@log_level = warning@' ${FILE_CONF_PHP_FPM}
    sed -i 's@^;emergency_restart_threshold =.*@emergency_restart_threshold = 60@' ${FILE_CONF_PHP_FPM}
    sed -i 's@^;emergency_restart_interval =.*@emergency_restart_interval = 1m@' ${FILE_CONF_PHP_FPM}
    sed -i 's@^;process_control_timeout =.*@process_control_timeout = 1m@' ${FILE_CONF_PHP_FPM}
    sed -i 's@^;daemonize =.*@daemonize = yes@' ${FILE_CONF_PHP_FPM}
    color green "php-fpm.conf 配置成功"

    # Set www.conf File
    mkdir -p /var/run/php-fpm
    FILE_CONF_PHP_FPM_WWW="${INSTALL_PHP_PATH}/etc/php-fpm.d/www.conf"
    cp -f ${FILE_CONF_PHP_FPM_WWW}.default ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^listen =.*@listen = /var/run/php-fpm.sock@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^;listen.owner =\(.*\)@listen.owner =\1@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^;listen.group =\(.*\)@listen.group =\1@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^;listen.mode =\(.*\)@listen.mode =\1@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^;listen.allowed_clients =.*@listen.allowed_clients = 127.0.0.1@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^pm =.*@pm = dynamic@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^pm.max_children =.*@pm.max_children = 16@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^pm.start_servers =.*@pm.start_servers = 4@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^pm.min_spare_servers =.*@pm.min_spare_servers = 4@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^pm.max_spare_servers =.*@pm.max_spare_servers = 16@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^;pm.max_requests =.*@pm.max_requests = 10240@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^;slowlog = \(.*\)@slowlog = var/\1@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^;request_slowlog_timeout =.*@request_slowlog_timeout = 5s@' ${FILE_CONF_PHP_FPM_WWW}
    sed -i 's@^;catch_workers_output =.*@catch_workers_output = yes@' ${FILE_CONF_PHP_FPM_WWW}
    color green "www.conf 配置成功"

    # Result
    color ""
    color green "===================== PHP 配置完成 ====================="
    color ""
}

# Test PHP
function test_php() {
    FILE_APACHE_CONF="${INSTALL_APACHE_PATH}/conf/extra/vhost/80.localhost.conf"
    FILE_PHPINFO_TEST="${WWW_PATH}/default/index.php"

    if [[ -s ${FILE_APACHE_CONF} ]]; then
        # Write Test File
        echo "<?php phpinfo();" > ${FILE_PHPINFO_TEST}

        sed -i 's@^#\(.*\)@\1@' ${FILE_APACHE_CONF}
        systemctl restart httpd.service
        systemctl restart php-fpm.service

        INDEX_CONTENT="$(curl -s http://localhost/)"
        if [[ $(echo ${INDEX_CONTENT} | grep -c "PHP Version ${LATEST_PHP_VERSION}") != 0 ]]; then
            color green "测试通过"
        else
            color red "测试失败"
        fi

        # Remove Test File
        rm -rf ${FILE_PHPINFO_TEST}
    else
        systemctl restart php-fpm.service

        color yellow "跳过测试"
    fi
}

# Main
function main() {
    color ""
    color blue "===================== PHP 安装程序启动 ====================="

    remove_yum_php
    install_dependencies

    check_re2c
    check_pcre2
    check_libzip
    install_php

    configure_php
    test_php

    color ""
    color green "===================== PHP 安装程序已完成 ====================="
    color ""
}


################### Start ####################
check_system_info
check_installed_info
get_version_info

# Show Install Information
clear
color blue "##########################################################"
color blue "# Auto Install Script for PHP 7.3                        #"
color blue "# Author: ttionya                                        #"
color blue "##########################################################"
color ""
color yellow "将安装 PHP ${LATEST_PHP_VERSION}"
color ""
color yellow "依赖："
color yellow "    - PCRE 2 ${LATEST_PCRE2_VERSION}"
color yellow "    - re2c ${LATEST_RE2C_VERSION}"
color yellow "    - libzip ${LATEST_LIBZIP_VERSION}"
color ""
color yellow "CPU 核心数: ${CPU_NUM} 个"
color ""
color yellow "内存大小: ${MAM} M，${CONFIGURE_FILE_INFO_MSG}"
color ""
color x "是否安装 ？ (y/n)"
read -p "(Default: n):" CHECK_INSTALL

# Check Install
if [[ $(echo ${CHECK_INSTALL:-n} | tr [a-z] [A-Z]) == Y ]]; then
    main
else
    color ""
    color blue "PHP 安装被取消..."
fi
################### End ####################

# Ver1.0.1
# - 修正安装完成后重启 httpd 失败的问题
# - 解压前删除文件夹，防止 make 缓存
#
# Ver1.0.2
# - 修改 sock 文件位置，解决 systemctl 启动 php-fpm 出现无法找到 sock 文件的情况
#
# Ver1.0.3
# - 修改 MySQL sock 文件位置
# - 修正 httpd 服务经常起不来的问题
#
# Ver2.0.0
# - 优化变量命名方式
# - 拆分流程到函数中
# - 升级至 PHP 7.3
# - 使用 PCRE 2
# - 编译安装 libzip 以支持 ZIP
# - 用询问替代强制重新安装依赖
# - 优化脚本
