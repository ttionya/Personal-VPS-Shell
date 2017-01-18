#!/bin/bash

# Version: 1.0.0
# Author: ttionya


################### Customer Setting ####################
# 最后不要加上斜杠/
# PHP 安装路径
Installed_PHP_Path="/usr/local/php"
# Apache 安装路径
Installed_Apache_Path="/usr/local/apache"
# PCRE 安装路径，暂不支持 PCRE 2
Installed_PCRE_Path="/usr/local/pcre"
# libiconv 安装路径
Installed_libiconv_Path="/usr/local/libiconv"


################### Check Info Start ####################
# Check root User
if [ $EUID != 0 ]; then
   echo "错误：该脚本必须以 root 身份运行"
   exit 1
fi

# Check PHP Path
if [ ! -d $Installed_PHP_Path ]; then
    echo "错误：未在指定位置找到 php 目录"
    exit 1
fi

# Check Apache Path
if [ ! -d $Installed_Apache_Path ]; then
    echo "错误：未在指定位置找到 apache 目录"
    exit 1
fi

# Check PCRE Path
if [ ! -d $Installed_PCRE_Path ]; then
    echo "错误：未在指定位置找到 pcre 目录"
    exit 1
fi

# Check libiconv Path
if [ ! -d $Installed_libiconv_Path ]; then
    echo "错误：未在指定位置找到 libiconv 目录"
    exit 1
fi

# Check CentOS Version
# CentOS 6.X Only
if [ -s /etc/redhat-release ]; then
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/redhat-release`
else
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/issue`
fi
CentOS_Ver=${CentOS_Ver%%.*}
if [ $CentOS_Ver != 6 ]; then
    echo "错误：该脚本仅支持 CentOS 6.X 版本"
    exit 1
fi

# Check PHP Version
# PHP 7.0.X 7.1.X
Installed_PHP_Ver=`php -r 'echo PHP_VERSION;' 2>/dev/null`
PHP_Ver=`echo $Installed_PHP_Ver | awk -F. '{print $1$2}'`
Minor_PHP_Ver=`echo $Installed_PHP_Ver | awk -F. '{print $2}'`
if [[ $PHP_Ver != 70 && $PHP_Ver != 71 ]]; then
    echo "错误：该脚本仅支持 PHP 7.$Minor_PHP_Ver.X 版本"
    exit 1
fi

echo "正在获取软件信息..."

Latest_PHP_Ver=`curl -s http://php.net/downloads.php | awk '/Changelog/{print $2}' | grep 7.$Minor_PHP_Ver`

# Check CPU Number
Cpu_Num=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
################### Check Info End ####################

# Get/Set Ram Information
Mem=`free -m | awk '/Mem/ {print $2}'`
if [ $Mem -lt 1000 ]; then
    FileInfo='--disable-fileinfo'
    info="内存不足，已禁用 fileinfo 编译选项"
else
    FileInfo=''
    info="未禁用 fileinfo 编译选项"
fi

# Update PHP to Latest Version
function update_php() {
    echo ""
    echo "===================== PHP 升级程序 启动 ===================="
    cd /usr/local/src
    
    # Download Latest PHP Version
    if [ ! -s php-$Latest_PHP_Ver.tar.gz ]; then
        wget -c -t3 -T60 "http://php.net/distributions/php-"$Latest_PHP_Ver".tar.gz"
        if [ $? != 0 ]; then
            rm -rf php-$Latest_PHP_Ver.tar.gz

            # Retry Chinese Mirrors
            wget -c -t3 -T60 "http://cn2.php.net/distributions/php-"$Latest_PHP_Ver".tar.gz"
            if [ $? != 0 ]; then
                rm -rf apr-$Latest_APR_Ver.tar.gz
                echo "PHP 下载失败"
                exit 1
            fi
        fi
    fi
    
    # Untar PHP gz package
    tar -zxf php-$Latest_PHP_Ver.tar.gz
    echo ""
    echo "PHP 源码包已解压"
    echo ""
    
    # Configure && Make
    cd php-$Latest_PHP_Ver/
    ./configure \
    --prefix=$Installed_PHP_Path \
    --with-apxs2=$Installed_Apache_Path/bin/apxs \
    --with-config-file-path=$Installed_PHP_Path/etc \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-mysql-sock=/tmp/mysql.sock \
    --with-pcre-dir=$Installed_PCRE_Path \
    --with-iconv-dir=$Installed_libiconv_Path \
    --with-libxml-dir=/usr \
    --with-icu-dir=/usr \
    --with-mhash \
    --with-bz2 \
    --with-curl \
    --with-freetype-dir \
    --with-jpeg-dir \
    --with-png-dir \
    --with-gd \
    --with-gettext \
    --with-gmp \
    --with-ldap \
    --with-ldap-sasl \
    --with-mcrypt \
    --with-openssl \
    --with-xmlrpc \
    --with-xsl \
    --with-zlib \
    --with-imap \
    --with-imap-ssl \
    --with-kerberos \
    --without-pear \
    --enable-mysqlnd \
    --enable-bcmath \
    --enable-calendar \
    --enable-sysvsem \
    --enable-exif \
    --enable-ftp \
    --enable-gd-native-ttf \
    --enable-intl \
    --enable-mbstring \
    --enable-pcntl \
    --enable-shmop \
    --enable-soap \
    --enable-sockets \
    --enable-wddx \
    --enable-zip $FileInfo
    if [ $? != 0 ]; then
        echo "PHP 配置失败"
        exit 1
    fi
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        echo "PHP 编译失败"
        exit 1
    fi
    
    # Backup Old PHP Directory
    if [[ -d "$Installed_PHP_Path.bak" && -d "$Installed_PHP_Path" ]]; then
        rm -rf $Installed_PHP_Path.bak/
    fi
    mv $Installed_PHP_Path $Installed_PHP_Path.bak
    
    # Install PHP
    make install
    if [ $? != 0 ]; then
        echo "PHP 安装失败"
        rm -rf $Installed_PHP_Path
        mv $Installed_PHP_Path.bak $Installed_PHP_Path
        exit 1
    fi
    
    # Move Files
    mkdir -p $Installed_PHP_Path/etc
    cp -f /usr/local/src/php-$Latest_PHP_Ver/php.ini-production $Installed_PHP_Path/etc/php.ini.new
    cp -f $Installed_PHP_Path.bak/etc/php.ini $Installed_PHP_Path/etc/php.ini
    cp -rnf $Installed_PHP_Path.bak/lib/php/extensions/ $Installed_PHP_Path/lib/php/
    
    # Clean Up Old Files
    rm -rf /usr/local/src/php-$Installed_PHP_Ver/
    rm -f /usr/local/src/php-$Installed_PHP_Ver.tar.gz
    
    # Restart
    /etc/init.d/httpd restart
    echo "===================== PHP 升级完成 ===================="
}

# Show Upgrade Information
clear
echo "##########################################################"
echo "# Auto Update Script for PHP 7                           #"
echo "# System Required:  CentOS / RedHat 6.X                  #"
echo "# Web Server Required:  Apache                           #"
echo "# Author: ttionya                                        #"
echo "##########################################################"
echo ""
echo "最新版 PHP 7: $Latest_PHP_Ver"
echo "已安装 PHP 7: $Installed_PHP_Ver"
echo ""
echo "内存大小： $Mem M"
echo "$info"
echo ""
echo "是否更新 PHP $Latest_PHP_Ver ？ (y/n)"
read -p "(Default: n):" Check_Update
if [ -z $Check_Update ]; then
    Check_Update="n"
fi

# Check Update
if [[ $Check_Update == y || $Check_Update == Y ]]; then
    update_php
else
    echo ""
    echo "PHP 升级被取消，未作任何更改..."
    echo ""
fi