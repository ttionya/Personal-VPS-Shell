#!/bin/bash

# Version: 1.0.3
# Author: ttionya


################### Customer Setting ####################
# 低权限用户和组
Low_User="www"
Low_Group="www"
# 默认网站路径
WWW_Path="/data/www"
# PCRE 版本号
Latest_PCRE_Ver="8.41"
# libiconv 版本号
Latest_libiconv_Ver="1.15"
# re2c 版本号
Latest_re2c_Ver="1.0.3"
# PHP 版本号
Latest_PHP_Ver="7.2.2"
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# Apache 安装路径
Install_Apache_Path="/usr/local/apache"
# PHP 安装路径
Install_PHP_Path="/usr/local/php"
# PCRE 安装路径，暂不支持 PCRE 2
Install_PCRE_Path="/usr/local/pcre"
# libiconv 安装路径
Install_libiconv_Path="/usr/local/iconv"


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

# Check PHP Path
if [ -d $Install_PHP_Path ]; then
    echo -e "\033[33m警告：php 目录 $Install_PHP_Path 已存在\033[0m"
    Path_Exist=1
fi

# Check PCRE Path
if [ -d $Install_PCRE_Path ]; then
    echo -e "\033[33m警告：pcre 目录 $Install_PCRE_Path 已存在\033[0m"
    Path_Exist=1
fi

# Check libiconv Path
if [ -d $Install_libiconv_Path ]; then
    echo -e "\033[33m警告：libiconv 目录 $Install_libiconv_Path 已存在\033[0m"
    Path_Exist=1
fi

# Check Exist Path
if [[ $Path_Exist == 1 ]]; then
    echo -e "\033[33m警告：继续下一步会立即删除已存在的目录，是否要继续 ？ (y/n)\033[0m"
    read -p "(Default: n):" Check_Next
    if [ -z $Check_Next ]; then
        Check_Next="n"
    fi

    # Check Next
    if [[ $Check_Next == y || $Check_Next == Y ]]; then
        pkill -9 php-fpm
        rm -rf $Install_PHP_Path $Install_PCRE_Path $Install_libiconv_Path
    else
        echo ""
        echo -e "\033[34mPHP 安装被取消，未作任何更改...\033[0m"
        exit 0
    fi
fi

# Get/Set Ram Information
Mem=`free -m | awk '{a+=$2}END{print a}'`
if [ $Mem -lt 1000 ]; then
    FileInfo='--disable-fileinfo'
    info="内存不足，已禁用 fileinfo 编译选项"
else
    FileInfo=''
    info="未禁用 fileinfo 编译选项"
fi

# Check CPU Number
Cpu_Num=`cat /proc/cpuinfo | grep -c 'processor'`
################### Check Info End ####################

function install_php() {
    echo ""
    echo -e "\033[33m==================== PHP 安装程序 启动 ====================\033[0m"
    cd /usr/local/src

    # Remove && Install && Update
    rpm -e --nodeps php
    yum -y remove php
    curl https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/lamp_devel.sh | bash -
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：依赖安装失败\033[0m"
        exit 1
    fi

    # Download PCRE Version
    echo ""
    if [ ! -s pcre-$Latest_PCRE_Ver.tar.gz ]; then
        wget -c -t3 -T60 "https://sourceforge.net/projects/pcre/files/pcre/$Latest_PCRE_Ver/pcre-$Latest_PCRE_Ver.tar.gz/download" -O pcre-$Latest_PCRE_Ver.tar.gz
        if [ $? != 0 ]; then
            rm -rf pcre-$Latest_PCRE_Ver.tar.gz
            echo ""
            echo -e "\033[31m错误：PCRE 下载失败\033[0m"
            exit 1
        fi
    fi

    # Configure && Make && Install
    rm -rf pcre-$Latest_PCRE_Ver
    tar -zxf pcre-$Latest_PCRE_Ver.tar.gz
    cd pcre-$Latest_PCRE_Ver
    ./configure --prefix=$Install_PCRE_Path
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：PCRE 配置失败\033[0m"
        exit 1
    fi
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：PCRE 编译失败\033[0m"
        exit 1
    fi
    make install
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：PCRE 安装失败\033[0m"
        rm -rf $Install_PCRE_Path
        exit 1
    fi

    # Clean Up
    rm -rf /usr/local/src/pcre-$Latest_PCRE_Ver/

    # Echo
    echo -e "\033[32m==================== PCRE 安装完成 ====================\033[0m"
    echo ""

    # Download libiconv Version
    cd /usr/local/src
    if [ ! -s libiconv-$Latest_libiconv_Ver.tar.gz ]; then
        wget -c -t3 -T60 "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$Latest_libiconv_Ver.tar.gz"
        if [ $? != 0 ]; then
            rm -rf libiconv-$Latest_libiconv_Ver.tar.gz
            echo ""
            echo -e "\033[31m错误：libiconv 下载失败\033[0m"
            exit 1
        fi
    fi

    # Configure && Make && Install
    rm -rf libiconv-$Latest_libiconv_Ver
    tar -zxf libiconv-$Latest_libiconv_Ver.tar.gz
    cd libiconv-$Latest_libiconv_Ver
    ./configure --prefix=$Install_libiconv_Path
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：libiconv 配置失败\033[0m"
        exit 1
    fi
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：libiconv 编译失败\033[0m"
        exit 1
    fi
    make install
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：libiconv 安装失败\033[0m"
        rm -rf $Install_libiconv_Path
        exit 1
    fi

    # Clean Up
    rm -rf /usr/local/src/libiconv-$Latest_libiconv_Ver/

    # Echo
    echo -e "\033[32m==================== libiconv 安装完成 ====================\033[0m"
    echo ""

    # Download re2c Version
    cd /usr/local/src
    if [ ! -s re2c-$Latest_re2c_Ver.tar.gz ]; then
        wget -c -t3 -T60 "https://github.com/skvadrik/re2c/releases/download/$Latest_re2c_Ver/re2c-$Latest_re2c_Ver.tar.gz"
        if [ $? != 0 ]; then
            rm -rf re2c-$Latest_re2c_Ver.tar.gz
            echo ""
            echo -e "\033[31m错误：re2c 下载失败\033[0m"
            exit 1
        fi
    fi

    # Configure && Make && Install
    rm -rf re2c-$Latest_re2c_Ver
    tar -zxf re2c-$Latest_re2c_Ver.tar.gz
    cd re2c-$Latest_re2c_Ver
    ./configure
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：re2c 配置失败\033[0m"
        exit 1
    fi
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：re2c 编译失败\033[0m"
        exit 1
    fi
    make install
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：re2c 安装失败\033[0m"
        exit 1
    fi

    # Clean Up
    rm -rf /usr/local/src/re2c-$Latest_re2c_Ver/

    # Echo
    echo -e "\033[32m==================== re2c 安装完成 ====================\033[0m"
    echo ""

    # Download Latest PHP Version
    cd /usr/local/src
    if [ ! -s php-$Latest_PHP_Ver.tar.gz ]; then
        wget -c -t3 -T60 "http://php.net/distributions/php-$Latest_PHP_Ver.tar.gz"
        if [ $? != 0 ]; then
            rm -rf php-$Latest_PHP_Ver.tar.gz

            # Retry China Mirrors
            wget -c -t3 -T60 "http://cn2.php.net/distributions/php-$Latest_PHP_Ver.tar.gz"
            if [ $? != 0 ]; then
                rm -rf php-$Latest_PHP_Ver.tar.gz
                echo ""
                echo -e "\033[31m错误：PHP 下载失败\033[0m"
                exit 1
            fi
        fi
    fi

    # Configure && Make && Install
    rm -rf php-$Latest_PHP_Ver
    tar -zxf php-$Latest_PHP_Ver.tar.gz
    cd php-$Latest_PHP_Ver
    ./configure \
    --prefix=$Install_PHP_Path \
    --with-config-file-path=$Install_PHP_Path/etc \
    --with-libdir=lib64 \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-mysql-sock=/var/lib/mysql/mysql.sock \
    --with-pcre-dir=$Install_PCRE_Path \
    --with-iconv-dir=$Install_libiconv_Path \
    --with-libxml-dir=/usr \
    --with-icu-dir=/usr \
    --with-openssl \
    --enable-fpm \
    --with-fpm-user=$Low_User \
    --with-fpm-group=$Low_Group \
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
    --enable-sysvsem \
    --enable-exif \
    --enable-ftp \
    --enable-intl \
    --enable-mbstring \
    --enable-pcntl \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-wddx \
    --enable-zip $FileInfo
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：PHP 配置失败\033[0m"
        exit 1
    fi
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：PHP 编译失败\033[0m"
        exit 1
    fi
    make install
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：PHP 安装失败\033[0m"
        rm -rf $Install_PHP_Path
        exit 1
    fi

    echo -e "\033[32m==================== PHP 安装完成，开始进行配置 ====================\033[0m"

    # Configure
    mkdir -p $Install_PHP_Path/etc
    cp -f php.ini-production $Install_PHP_Path/etc/php.ini
    cp -f sapi/fpm/php-fpm.service /usr/lib/systemd/system/
    cp -f $Install_PHP_Path/etc/php-fpm.conf.default $Install_PHP_Path/etc/php-fpm.conf
    cp -f $Install_PHP_Path/etc/php-fpm.d/www.conf.default $Install_PHP_Path/etc/php-fpm.d/www.conf
    mkdir -p /var/run/php-fpm

    if [[ `grep -c "$Install_PHP_Path/bin/:$Install_PHP_Path/sbin/" /etc/profile` == 0 ]]; then
        echo "export PATH=\${PATH}:$Install_PHP_Path/bin/:$Install_PHP_Path/sbin/" >> /etc/profile
        source /etc/profile
    fi

    systemctl enable php-fpm
    if [ $? != 0 ]; then
        echo -e "\033[33m警告：php-fpm 设置开机自启动失败\033[0m"
    else
        echo -e "\033[32mphp-fpm 设置开机自启动成功\033[0m"
    fi

    # Set php.ini Config File
    sed -i 's@^short_open_tag = Off@short_open_tag = On@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket,pfsockopen@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^expose_php = On@expose_php = Off@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^allow_url_fopen.*@allow_url_fopen = Off@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^max_execution_time.*@max_execution_time = 300@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^;upload_tmp_dir.*@upload_tmp_dir = /tmp@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^post_max_size.*@post_max_size = 50M@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^upload_max_filesize.*@upload_max_filesize = 50M@' $Install_PHP_Path/etc/php.ini
    sed -i "s@extension_dir = \"ext\"@extension_dir = \"ext\"\nextension_dir = \"$Install_PHP_Path/lib/php/extensions/`ls /usr/local/php/lib/php/extensions/`\"@" $Install_PHP_Path/etc/php.ini
    echo -e "\033[32m基本设置配置成功\033[0m"

    # Date
    sed -i 's@^;date.timezone.*@date.timezone = Asia/Shanghai@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^request_order.*@request_order = "CGP"@' $Install_PHP_Path/etc/php.ini
    echo -e "\033[32m时区配置成功\033[0m"

    # Session 模块
    sed -i 's@^session.cookie_httponly.*@session.cookie_httponly = 1@' $Install_PHP_Path/etc/php.ini
    echo -e "\033[32m会话配置成功\033[0m"

    # Opcache 模块
    sed -i 's@^\[opcache\]@[opcache]\nzend_extension=opcache.so@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^;opcache.enable=.*@opcache.enable=1@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^;opcache.enable_cli.*@opcache.enable_cli=1@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^;opcache.memory_consumption.*@opcache.memory_consumption=128@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^;opcache.interned_strings_buffer.*@opcache.interned_strings_buffer=8@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^;opcache.max_accelerated_files.*@opcache.max_accelerated_files=10000@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^;opcache.max_wasted_percentage.*@opcache.max_wasted_percentage=5@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^;opcache.validate_timestamps.*@opcache.validate_timestamps=1@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^;opcache.revalidate_freq.*@opcache.revalidate_freq=60@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^;opcache.file_cache=.*@opcache.file_cache=/tmp@' $Install_PHP_Path/etc/php.ini
    sed -i 's@^;opcache.file_cache_only=.*@opcache.file_cache_only=0@' $Install_PHP_Path/etc/php.ini
    echo -e "\033[32mOpcache 配置成功\033[0m"

    # php-fpm.conf
    sed -i 's@^;pid =\(.*\)@pid =\1@' $Install_PHP_Path/etc/php-fpm.conf
    sed -i 's@^;error_log =\(.*\)@error_log =\1@' $Install_PHP_Path/etc/php-fpm.conf
    sed -i 's@^;log_level =.*@log_level = warning@' $Install_PHP_Path/etc/php-fpm.conf
    sed -i 's@^;daemonize =.*@daemonize = yes@' $Install_PHP_Path/etc/php-fpm.conf
    sed -i 's@^;emergency_restart_threshold =.*@emergency_restart_threshold = 60@' $Install_PHP_Path/etc/php-fpm.conf
    sed -i 's@^;emergency_restart_interval =.*@emergency_restart_interval = 1m@' $Install_PHP_Path/etc/php-fpm.conf
    sed -i 's@^;process_control_timeout =.*@process_control_timeout = 1m@' $Install_PHP_Path/etc/php-fpm.conf
    echo -e "\033[32mphp-fpm.conf 配置成功\033[0m"

    # www.conf
    sed -i 's@^listen =.*@listen = /var/run/php-fpm.sock@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^;listen.owner =\(.*\)@listen.owner =\1@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^;listen.group =\(.*\)@listen.group =\1@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^;listen.mode =\(.*\)@listen.mode =\1@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^;listen.allowed_clients =.*@listen.allowed_clients = 127.0.0.1@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^pm =.*@pm = dynamic@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^pm.max_children =.*@pm.max_children = 16@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^pm.start_servers =.*@pm.start_servers = 4@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^pm.min_spare_servers =.*@pm.min_spare_servers = 4@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^pm.max_spare_servers =.*@pm.max_spare_servers = 16@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^;pm.max_requests =.*@pm.max_requests = 10240@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^;slowlog = \(.*\)@slowlog = var/\1@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^;request_slowlog_timeout =.*@request_slowlog_timeout = 5s@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    sed -i 's@^;catch_workers_output =.*@catch_workers_output = yes@' $Install_PHP_Path/etc/php-fpm.d/www.conf
    echo -e "\033[32mwww.conf 配置成功\033[0m"

    # Clean Up
    cd ~
    rm -rf /usr/local/src/php-$Latest_PHP_Ver/

    # Link Logs
    rm -rf /var/log/php-fpm/
    ln -s $Install_PHP_Path/var/log /var/log/php-fpm

    echo -e "\033[32m==================== PHP 配置完成，开始进行测试 ====================\033[0m"

    echo "<?php phpinfo();" > $WWW_Path/default/index.php
    echo ""
    sed -i 's@^#\(.*\)@\1@' $Install_Apache_Path/conf/extra/vhost/80.localhost.conf
    systemctl stop httpd.service
    systemctl start httpd.service
    systemctl restart httpd.service
    service php-fpm restart
    Index_Content=`curl -s http://localhost/`
    if [[ `echo "$Index_Content" | grep -c "PHP Version $Latest_PHP_Ver"` != 0 ]]; then
        echo -e "\033[32m测试通过\033[0m"
    else
        echo -e "\033[31m测试失败\033[0m"
    fi
}

# Show Install Information
clear
echo -e "\033[34m##########################################################\033[0m"
echo -e "\033[34m# Auto Install Script for PHP 7.2                        #\033[0m"
echo -e "\033[34m# System Required:  CentOS / RedHat 7.X                  #\033[0m"
echo -e "\033[34m# Author: ttionya                                        #\033[0m"
echo -e "\033[34m##########################################################\033[0m"
echo ""
echo -e "\033[33m将安装 PHP $Latest_PHP_Ver\033[0m"
echo ""
echo -e "\033[33m将安装 PCRE $Latest_PCRE_Ver\033[0m"
echo ""
echo -e "\033[33m将安装 libiconv $Latest_libiconv_Ver\033[0m"
echo ""
echo -e "\033[33m将安装 re2c $Latest_re2c_Ver\033[0m"
echo ""
echo -e "\033[33m内存大小： $Mem M\033[0m"
echo -e "\033[33m$info\033[0m"
echo ""
echo -e "\033[33mCPU 线程数： $Cpu_Num 个\033[0m"
echo ""
echo "是否安装 ？ (y/n)"
read -p "(Default: n):" Check_Install
if [ -z $Check_Install ]; then
    Check_Install="n"
fi

# Check Install
if [[ $Check_Install == y || $Check_Install == Y ]]; then
    install_php
else
    echo ""
    echo -e "\033[34mPHP 安装被取消，未作任何更改...\033[0m"
fi

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