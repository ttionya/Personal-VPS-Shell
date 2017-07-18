#!/bin/bash

# Version: 1.0.1
# Author: ttionya


################### Customer Setting ####################
# 最后不要加上斜杠/
# Apache 安装路径
Installed_Apache_Path="/usr/local/apache"
# PCRE 安装路径，暂不支持 PCRE 2
Installed_PCRE_Path="/usr/local/pcre"
# OpenSSL 安装路径，暂只支持 OpenSSL 1.0.2
Installed_OpenSSL_Path="/usr/local/openssl"
# nghttp2 安装路径
Installed_nghttp2_Path="/usr/local/nghttp2"


################### Check Info Start ####################
# Check root User
if [ $EUID != 0 ]; then
   echo "错误：该脚本必须以 root 身份运行"
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

# Check OpenSSL Path
if [ ! -d $Installed_OpenSSL_Path ]; then
    echo "错误：未在指定位置找到 openssl 目录"
    exit 1
fi

# Check nghttp2 Path
if [ ! -d $Installed_nghttp2_Path ]; then
    echo "错误：未在指定位置找到 nghttp2 目录"
    exit 1
fi


# Check CentOS Version
# CentOS 6.X / 7.X
if [ -s /etc/redhat-release ]; then
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/redhat-release`
else
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/issue`
fi
CentOS_Ver=${CentOS_Ver%%.*}
if [[ $CentOS_Ver != 6 && $CentOS_Ver != 7 ]]; then
    echo "错误：该脚本仅支持 CentOS 6.X / 7.X 版本"
    exit 1
fi

echo "正在获取软件信息..."

# Check PCRE Version
Installed_PCRE_Ver=`$Installed_PCRE_Path/bin/pcre-config --version`
Latest_PCRE_Ver=`curl --retry 3 -s https://sourceforge.net/projects/pcre/files/pcre/ | grep "Click to enter" | head -n 1 | awk -F" " '{print $4}' | tr -d "\""`

# Check OpenSSL Version
Installed_OpenSSL_Ver=`$Installed_OpenSSL_Path/bin/openssl version | awk -F" " '{print $2}'`
Latest_OpenSSL_Ver=`curl --retry 3 -s https://www.openssl.org/source/ | grep -oE "openssl-1.0.2[a-z]" | awk -F"-" '{print $2}' | head -n 1`

# Check nghttp2 Version
Latest_nghttp2_Ver=`curl --retry 3 -s https://github.com/nghttp2/nghttp2/releases | grep "css-truncate-target" | head -n 1 | grep -oE "v[0-9.]+" | sed "s/^.\(.*\)$/\1/"`

# Check APR/APR-util Version
APRs_Url=`curl --retry 3 -s https://www.apache.org/dyn/closer.cgi | grep -oE "<strong>[^<]*</strong>" | head -n 1 | sed "s@<strong>\(.*\)</strong>@\1@g"`/apr/
APRs_Content=`curl --retry 3 -s $APRs_Url`
Latest_APR_Url=$APRs_Url`echo $APRs_Content | grep -oP "apr-1.[6-9][^\"]*.tar.gz" | tail -n 1`
Latest_APR_Util_Url=$APRs_Url`echo $APRs_Content | grep -oP "apr-util-1.[6-9][^\"]*.tar.gz" | tail -n 1`
Latest_APR_Ver=`echo $Latest_APR_Url | grep -oE "([0-9].)*[0-9]"`
Latest_APR_Util_Ver=`echo $Latest_APR_Util_Url | grep -oE "([0-9].)*[0-9]"`

# Check Apache Version
Installed_Apache_Ver=`$Installed_Apache_Path/bin/httpd -v | grep -oE "2.4.[0-9]*"`
Latest_Apache_Url=`curl --retry 3 -s http://httpd.apache.org/download.cgi | grep -oE "http[s]?://.*//httpd/httpd-2.4.[0-9]*.tar.gz"`
Latest_Apache_Ver=`echo $Latest_Apache_Url | grep -oE "2.4.[0-9]*"`

# Check CPU Number
Cpu_Num=`cat /proc/cpuinfo | grep 'processor' | wc -l`
################### Check Info End ####################

function update_apache() {
    echo ""
    echo "===================== Apache 升级程序 启动 ===================="
    cd /usr/local/src

    # Download PCRE Version
    echo ""
    if [[ $Installed_PCRE_Ver == $Latest_PCRE_Ver ]]; then
        echo "PCRE 已是最新版本！"
    else
        if [ ! -s pcre-$Latest_PCRE_Ver.tar.gz ]; then
            wget -c -t3 -T60 "https://sourceforge.net/projects/pcre/files/pcre/$Latest_PCRE_Ver/pcre-$Latest_PCRE_Ver.tar.gz/download" -O pcre-$Latest_PCRE_Ver.tar.gz
            if [ $? != 0 ]; then
                rm -rf pcre-$Latest_PCRE_Ver.tar.gz
                echo "PCRE 下载失败"
                exit 1
            fi
        fi

        # Configure && Make
        tar -zxf pcre-$Latest_PCRE_Ver.tar.gz
        cd pcre-$Latest_PCRE_Ver
        ./configure --prefix=$Installed_PCRE_Path
        if [ $? != 0 ]; then
            echo "PCRE 配置失败"
            exit 1
        fi
        make -j $Cpu_Num
        if [ $? != 0 ]; then
            echo "PCRE 编译失败"
            exit 1
        fi

        # Backup Old PCRE Directory
        if [[ -d "$Installed_PCRE_Path.bak" && -d "$Installed_PCRE_Path" ]]; then
            rm -rf $Installed_PCRE_Path.bak/
        fi
        mv $Installed_PCRE_Path $Installed_PCRE_Path.bak

        # Install PCRE
        make install
        if [ $? != 0 ]; then
            echo "PCRE 安装失败"
            rm -rf $Installed_PCRE_Path
            mv $Installed_PCRE_Path.bak $Installed_PCRE_Path
            exit 1
        fi

        # Clean Up Old Files
        rm -rf /usr/local/src/pcre-$Installed_PCRE_Ver/
        rm -f /usr/local/src/pcre-$Installed_PCRE_Ver.tar.gz

        # Echo
        echo "===================== PCRE 升级完成 ===================="
    fi
    echo ""

    # Download OpenSSL Version
    cd /usr/local/src
    if [[ $Installed_OpenSSL_Ver == $Latest_OpenSSL_Ver ]]; then
        echo "OpenSSL 已是最新版本！"
    else
        if [ ! -s openssl-$Latest_OpenSSL_Ver.tar.gz ]; then
            wget -c -t3 -T60 "https://www.openssl.org/source/openssl-$Latest_OpenSSL_Ver.tar.gz" -O openssl-$Latest_OpenSSL_Ver.tar.gz
            if [ $? != 0 ]; then
                rm -rf openssl-$Latest_OpenSSL_Ver.tar.gz
                echo "OpenSSL 下载失败"
                exit 1
            fi
        fi

        # Configure && Make
        tar -zxf openssl-$Latest_OpenSSL_Ver.tar.gz
        cd openssl-$Latest_OpenSSL_Ver
        ./config --prefix=$Installed_OpenSSL_Path zlib-dynamic shared
        if [ $? != 0 ]; then
            echo "OpenSSL 配置失败"
            exit 1
        fi
        make -j $Cpu_Num
        if [ $? != 0 ]; then
            echo "OpenSSL 编译失败"
            exit 1
        fi
        make test
        if [ $? != 0 ]; then
            echo "OpenSSL 测试失败"
            exit 1
        fi

        # Backup Old OpenSSL Directory
        if [[ -d "$Installed_OpenSSL_Path.bak" && -d "$Installed_OpenSSL_Path" ]]; then
            rm -rf $Installed_OpenSSL_Path.bak/
        fi
        mv $Installed_OpenSSL_Path $Installed_OpenSSL_Path.bak

        # Install OpenSSL
        make install
        if [ $? != 0 ]; then
            echo "OpenSSL 安装失败"
            rm -rf $Installed_OpenSSL_Path
            mv $Installed_OpenSSL_Path.bak $Installed_OpenSSL_Path
            exit 1
        fi

        # Clean Up Old Files
        rm -rf /usr/local/src/openssl-$Installed_OpenSSL_Ver/
        rm -f /usr/local/src/openssl-$Installed_OpenSSL_Ver.tar.gz

        # Echo
        echo "===================== OpenSSL 升级完成 ===================="
    fi
    echo ""

    # Download nghttp2 Version
    cd /usr/local/src
    if [ ! -s nghttp2-$Latest_nghttp2_Ver.tar.gz ]; then
        wget -c -t3 -T60 "https://github.com/nghttp2/nghttp2/releases/download/v$Latest_nghttp2_Ver/nghttp2-$Latest_nghttp2_Ver.tar.gz" -O nghttp2-$Latest_nghttp2_Ver.tar.gz
        if [ $? != 0 ]; then
            rm -rf nghttp2-$Latest_nghttp2_Ver.tar.gz
            echo "nghttp2 下载失败"
            exit 1
        fi
    fi

    # Configure && Make
    tar -zxf nghttp2-$Latest_nghttp2_Ver.tar.gz
    cd nghttp2-$Latest_nghttp2_Ver
    ./configure --prefix=$Installed_nghttp2_Path
    if [ $? != 0 ]; then
        echo "nghttp2 配置失败"
        exit 1
    fi
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        echo "nghttp2 编译失败"
        exit 1
    fi

    # Backup Old nghttp2 Directory
    if [[ -d "$Installed_nghttp2_Path.bak" && -d "$Installed_nghttp2_Path" ]]; then
        rm -rf $Installed_nghttp2_Path.bak/
    fi
    mv $Installed_nghttp2_Path $Installed_nghttp2_Path.bak

    # Install nghttp2
    make install
    if [ $? != 0 ]; then
        echo "nghttp2 安装失败"
        rm -rf $Installed_nghttp2_Path
        mv $Installed_nghttp2_Path.bak $Installed_nghttp2_Path
        exit 1
    fi

    # Clean Up Old Files
    rm -rf nghttp2-*

    # Echo
    echo "===================== nghttp2 升级完成 ===================="
    echo ""

    # Download Latest APR/APR-util/Apache Version
    cd /usr/local/src
    if [ ! -s apr-$Latest_APR_Ver.tar.gz ]; then
        wget -c -t3 -T60 "$Latest_APR_Url"
        if [ $? != 0 ]; then
            rm -rf apr-$Latest_APR_Ver.tar.gz

            # Retry Chinese Mirrors
            wget -c -t3 -T60 "http://mirrors.hust.edu.cn/apache/apr/apr-"$Latest_APR_Ver".tar.gz"
            if [ $? != 0 ]; then
                rm -rf apr-$Latest_APR_Ver.tar.gz
                echo "APR 下载失败"
                exit 1
            fi
        fi
    fi
    if [ ! -s apr-$Latest_APR_Util_Ver.tar.gz ]; then
        wget -c -t3 -T60 "$Latest_APR_Util_Url"
        if [ $? != 0 ]; then
            rm -rf apr-util-$Latest_APR_Util_Ver.tar.gz

            # Retry Chinese Mirrors
            wget -c -t3 -T60 "http://mirrors.hust.edu.cn/apache/apr/apr-util-"$Latest_APR_Util_Ver".tar.gz"
            if [ $? != 0 ]; then
                rm -rf apr-util-$Latest_APR_Util_Ver.tar.gz
                echo "APR-util 下载失败"
                exit 1
            fi
        fi
    fi
    if [ ! -s httpd-$Latest_Apache_Ver.tar.gz ]; then
        wget -c -t3 -T60 "$Latest_Apache_Url"
        if [ $? != 0 ]; then
            rm -rf httpd-$Latest_Apache_Ver.tar.gz

            # Retry Chinese Mirrors
            wget -c -t3 -T60 "http://mirrors.hust.edu.cn/apache/httpd/httpd-"$Latest_Apache_Ver".tar.gz"
            if [ $? != 0 ]; then
                rm -rf httpd-$Latest_Apache_Ver.tar.gz
                echo "Apache 下载失败"
                exit 1
            fi
        fi
    fi

    # Untar gz package
    tar -zxf apr-$Latest_APR_Ver.tar.gz
    tar -zxf apr-util-$Latest_APR_Util_Ver.tar.gz
    tar -zxf httpd-$Latest_Apache_Ver.tar.gz
    echo ""
    echo "源码包已解压"
    echo ""

    # Move files
    mv apr-$Latest_APR_Ver httpd-$Latest_Apache_Ver/srclib/apr
    mv apr-util-$Latest_APR_Util_Ver httpd-$Latest_Apache_Ver/srclib/apr-util

    # Configure && Make
    cd httpd-$Latest_Apache_Ver
    ./configure \
    --prefix=$Installed_Apache_Path \
    --with-pcre=$Installed_PCRE_Path \
    --with-mpm=prefork \
    --with-included-apr \
    --with-ssl=$Installed_OpenSSL_Path \
    --with-nghttp2=$Installed_nghttp2_Path \
    --enable-modules=all \
    --enable-mods-shared=all \
    --enable-so \
    --enable-ssl \
    --enable-http2
    if [ $? != 0 ]; then
        echo "Apache 配置失败"
        exit 1
    fi
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        echo "Apache 编译失败"
        exit 1
    fi

    # Backup Old Apache Directory
    if [[ -d "$Installed_Apache_Path.bak" && -d "$Installed_Apache_Path" ]]; then
        rm -rf $Installed_Apache_Path.bak/
    fi
    mv $Installed_Apache_Path $Installed_Apache_Path.bak

    # Install Apache
    /etc/init.d/httpd stop
    make install
    if [ $? != 0 ]; then
        echo "Apache 安装失败"
        rm -rf $Installed_Apache_Path
        mv $Installed_Apache_Path.bak $Installed_Apache_Path
        /etc/init.d/httpd start
        exit 1
    fi

    # Move Files
    mv $Installed_Apache_Path/conf $Installed_Apache_Path/conf.new
    cp -rf $Installed_Apache_Path.bak/conf $Installed_Apache_Path/
    cp -rf $Installed_Apache_Path.bak/logs $Installed_Apache_Path/
    cp -rfu $Installed_Apache_Path.bak/modules $Installed_Apache_Path/

    # Clean Up Old Files
    rm -rf /usr/local/src/httpd-$Installed_Apache_Ver/
    rm -f /usr/local/src/httpd-$Installed_Apache_Ver.tar.gz

    # Restart
    /etc/init.d/httpd restart
    echo "===================== Apache 升级完成 ===================="
}

# Show Upgrade Information
clear
echo "##########################################################"
echo "# Auto Update Script for Apache 2.4 With HTTP/2          #"
echo "# System Required:  CentOS / RedHat 6.X / 7.X            #"
echo "# Author: ttionya                                        #"
echo "##########################################################"
echo ""
echo "最新版 Apache 2.4: $Latest_Apache_Ver"
echo "已安装 Apache 2.4: $Installed_Apache_Ver"
echo ""
echo "最新版 PCRE 版本：$Latest_PCRE_Ver"
echo "已安装 PCRE 版本：$Installed_PCRE_Ver"
echo ""
echo "最新版 OpenSSL 版本："$Latest_OpenSSL_Ver
echo "已安装 OpenSSL 版本："$Installed_OpenSSL_Ver
echo ""
echo "CPU 线程数： $Cpu_Num 个"
echo ""
echo "是否更新至 OpenSSL $Latest_OpenSSL_Ver、 PCRE $Latest_PCRE_Ver 以及 Apache $Latest_Apache_Ver ？ (y/n)"
read -p "(Default: n):" Check_Update
if [ -z $Check_Update ]; then
    Check_Update="n"
fi

# Check Update
if [[ $Check_Update == y || $Check_Update == Y ]]; then
    update_apache
else
    echo ""
    echo "Apache 升级被取消，未作任何更改..."
    echo ""
fi

# Ver1.0.1
# - 修复某些地区的 apr.apache.org/download.cgi 改版引起的问题