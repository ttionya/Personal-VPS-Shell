#!/bin/bash

# Version: 1.0.2
# Author: ttionya


################### Customer Setting ####################
# 低权限用户和组
Low_User="www"
Low_Group="www"
# 默认网站路径
WWW_Path="/data/www"
# PCRE 版本号
Latest_PCRE_Ver="8.41"
# nghttp2 版本号
Latest_nghttp2_Ver="1.30.0"
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# Apache 安装路径
Install_Apache_Path="/usr/local/apache"
# PCRE 安装路径，暂不支持 PCRE 2
Install_PCRE_Path="/usr/local/pcre"
# nghttp2 安装路径
Install_nghttp2_Path="/usr/local/nghttp2"


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

# Check Apache Path
if [ -d $Install_Apache_Path ]; then
    echo -e "\033[33m警告：apache 目录 $Install_Apache_Path 已存在\033[0m"
    Path_Exist=1
fi

# Check PCRE Path
if [ -d $Install_PCRE_Path ]; then
    echo -e "\033[33m警告：pcre 目录 $Install_PCRE_Path 已存在\033[0m"
    Path_Exist=1
fi

# Check nghttp2 Path
if [ -d $Install_nghttp2_Path ]; then
    echo -e "\033[33m警告：nghttp2 目录 $Install_nghttp2_Path 已存在\033[0m"
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
        pkill -9 httpd
        rm -rf $Install_Apache_Path $Install_PCRE_Path $Install_nghttp2_Path
    else
        echo ""
        echo -e "\033[34mApache 安装被取消，未作任何更改...\033[0m"
        exit 0
    fi
fi

echo ""
echo -e "\033[34m正在获取软件信息...\033[0m"

# Check APR/APR-util Version
APRs_Url=`curl --retry 3 -s https://www.apache.org/dyn/closer.cgi | grep -oE "<strong>[^<]*</strong>" | head -n 1 | sed "s@<strong>\(.*\)</strong>@\1@g"`/apr/
APRs_Content=`curl --retry 3 -s $APRs_Url`
Latest_APR_Url=$APRs_Url`echo $APRs_Content | grep -oP "apr-1.[6-9][^\"]*.tar.gz" | tail -n 1`
Latest_APR_Util_Url=$APRs_Url`echo $APRs_Content | grep -oP "apr-util-1.[6-9][^\"]*.tar.gz" | tail -n 1`
Latest_APR_Ver=`echo $Latest_APR_Url | grep -oE "([0-9].)*[0-9]"`
Latest_APR_Util_Ver=`echo $Latest_APR_Util_Url | grep -oE "([0-9].)*[0-9]"`

# Check Apache Version
Latest_Apache_Url=`curl --retry 3 -s http://httpd.apache.org/download.cgi | grep -oE "http[s]?://.*//httpd/httpd-2.4.[0-9]*.tar.gz"`
Latest_Apache_Ver=`echo $Latest_Apache_Url | grep -oE "2.4.[0-9]*"`

# Check CPU Number
Cpu_Num=`cat /proc/cpuinfo | grep 'processor' | wc -l`
################### Check Info End ####################

function install_apache() {
    echo ""
    echo -e "\033[33m===================== Apache 安装程序 启动 ====================\033[0m"
    cd /usr/local/src

    # Remove && Install && Update
    rpm -e --nodeps httpd
    yum -y remove httpd
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
    echo -e "\033[32m===================== PCRE 安装完成 ====================\033[0m"
    echo ""

    # Download nghttp2 Version
    cd /usr/local/src
    if [ ! -s nghttp2-$Latest_nghttp2_Ver.tar.gz ]; then
        wget -c -t3 -T60 "https://github.com/nghttp2/nghttp2/releases/download/v$Latest_nghttp2_Ver/nghttp2-$Latest_nghttp2_Ver.tar.gz" -O nghttp2-$Latest_nghttp2_Ver.tar.gz
        if [ $? != 0 ]; then
            rm -rf nghttp2-$Latest_nghttp2_Ver.tar.gz
            echo ""
            echo -e "\033[31m错误：nghttp2 下载失败\033[0m"
            exit 1
        fi
    fi

    # Configure && Make && Install
    tar -zxf nghttp2-$Latest_nghttp2_Ver.tar.gz
    cd nghttp2-$Latest_nghttp2_Ver
    ./configure --prefix=$Install_nghttp2_Path
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：nghttp2 配置失败\033[0m"
        exit 1
    fi
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：nghttp2 编译失败\033[0m"
        exit 1
    fi
    make install
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：nghttp2 安装失败\033[0m"
        rm -rf $Install_nghttp2_Path
        exit 1
    fi

    # Clean Up
    rm -rf /usr/local/src/nghttp2-$Latest_nghttp2_Ver/

    # Echo
    echo -e "\033[32m===================== nghttp2 安装完成 ====================\033[0m"
    echo ""

    # Download Latest APR/APR-util/Apache Version
    cd /usr/local/src
    if [ ! -s apr-$Latest_APR_Ver.tar.gz ]; then
        wget -c -t3 -T60 "$Latest_APR_Url"
        if [ $? != 0 ]; then
            rm -rf apr-$Latest_APR_Ver.tar.gz

            # Retry China Mirrors
            wget -c -t3 -T60 "http://mirrors.hust.edu.cn/apache/apr/apr-$Latest_APR_Ver.tar.gz"
            if [ $? != 0 ]; then
                rm -rf apr-$Latest_APR_Ver.tar.gz
                echo ""
                echo -e "\033[31m错误：APR 下载失败\033[0m"
                exit 1
            fi
        fi
    fi
    if [ ! -s apr-$Latest_APR_Util_Ver.tar.gz ]; then
        wget -c -t3 -T60 "$Latest_APR_Util_Url"
        if [ $? != 0 ]; then
            rm -rf apr-util-$Latest_APR_Util_Ver.tar.gz

            # Retry China Mirrors
            wget -c -t3 -T60 "http://mirrors.hust.edu.cn/apache/apr/apr-util-$Latest_APR_Util_Ver.tar.gz"
            if [ $? != 0 ]; then
                rm -rf apr-util-$Latest_APR_Util_Ver.tar.gz
                echo ""
                echo -e "\033[31m错误：APR-util 下载失败\033[0m"
                exit 1
            fi
        fi
    fi
    if [ ! -s httpd-$Latest_Apache_Ver.tar.gz ]; then
        wget -c -t3 -T60 "$Latest_Apache_Url"
        if [ $? != 0 ]; then
            rm -rf httpd-$Latest_Apache_Ver.tar.gz

            # Retry China Mirrors
            wget -c -t3 -T60 "http://mirrors.hust.edu.cn/apache/httpd/httpd-$Latest_Apache_Ver.tar.gz"
            if [ $? != 0 ]; then
                rm -rf httpd-$Latest_Apache_Ver.tar.gz
                echo ""
                echo -e "\033[31m错误：Apache 下载失败\033[0m"
                exit 1
            fi
        fi
    fi

    # Untar gz Package
    tar -zxf apr-$Latest_APR_Ver.tar.gz
    tar -zxf apr-util-$Latest_APR_Util_Ver.tar.gz
    tar -zxf httpd-$Latest_Apache_Ver.tar.gz
    echo ""
    echo -e "\033[32m源码包已解压\033[0m"

    # Move files
    mv apr-$Latest_APR_Ver httpd-$Latest_Apache_Ver/srclib/apr
    mv apr-util-$Latest_APR_Util_Ver httpd-$Latest_Apache_Ver/srclib/apr-util

    # Configure && Make
    cd httpd-$Latest_Apache_Ver
    ./configure \
    --prefix=$Install_Apache_Path \
    --with-pcre=$Install_PCRE_Path \
    --with-mpm=event \
    --with-included-apr \
    --with-ssl \
    --with-nghttp2=$Install_nghttp2_Path \
    --enable-modules=all \
    --enable-mods-shared=all \
    --enable-mpms-shared=all \
    --enable-so \
    --enable-ssl \
    --enable-http2
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：Apache 配置失败\033[0m"
        exit 1
    fi
    make -j $Cpu_Num
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：Apache 编译失败\033[0m"
        exit 1
    fi
    pkill -9 httpd
    make install
    if [ $? != 0 ]; then
        echo ""
        echo -e "\033[31m错误：Apache 安装失败\033[0m"
        rm -rf $Install_Apache_Path
        exit 1
    fi

    # Clean Up
    cd ~
    rm -rf /usr/local/src/httpd-$Latest_Apache_Ver/
    echo -e "\033[32m===================== Apache 安装完成，开始进行配置 ====================\033[0m"

    # Configure
    cp -f $Install_Apache_Path/bin/apachectl /etc/init.d/httpd
    sed -i '2a # chkconfig: - 85 15' /etc/init.d/httpd
    sed -i '3a # description: Apache is a World Wide Web server. It is used to server' /etc/init.d/httpd
    systemctl enable httpd.service
    if [ $? != 0 ]; then
        echo -e "\033[33m警告：httpd 设置开机自启动失败\033[0m"
    else
        echo -e "\033[32mhttpd 设置开机自启动成功\033[0m"
    fi

    rm -rf /etc/httpd
    ln -s $Install_Apache_Path /etc/httpd

    # 将这两个文件链接过来，以适应 init.d 脚本
    cd /usr/sbin/
    ln -fs $Install_Apache_Path/bin/httpd
    ln -fs $Install_Apache_Path/bin/apachectl

    # Link Logs
    rm -rf /var/log/httpd/
    ln -s $Install_Apache_Path/logs /var/log/httpd

    # Create User And Group
    groupadd -f $Low_Group
    if id -u $Low_User > /dev/null 2>&1; then
        echo -e "\033[34m用户已存在，跳过\033[0m"
    else
        useradd -g $Low_Group -s /sbin/nologin $Low_User
    fi

    mkdir -p $WWW_Path/default
    chmod -R 755 $WWW_Path

    # Set httpd Config File
    cp -f $Install_Apache_Path/conf/httpd.conf $Install_Apache_Path/conf/httpd.conf.bak
    sed -i 's@^#LoadModule\(.*\)mod_socache_shmcb.so@LoadModule\1mod_socache_shmcb.so@' $Install_Apache_Path/conf/httpd.conf # HTTPS
    sed -i 's@^#LoadModule\(.*\)mod_deflate.so@LoadModule\1mod_deflate.so@' $Install_Apache_Path/conf/httpd.conf # GZip
    sed -i 's@^#LoadModule\(.*\)mod_expires.so@LoadModule\1mod_expires.so@' $Install_Apache_Path/conf/httpd.conf # Cache
    sed -i 's@^#LoadModule\(.*\)mod_headers.so@LoadModule\1mod_headers.so@' $Install_Apache_Path/conf/httpd.conf # GZip
    sed -i 's@^#LoadModule\(.*\)mod_remoteip.so@LoadModule\1mod_remoteip.so@' $Install_Apache_Path/conf/httpd.conf # Proxy
    sed -i 's@^#LoadModule\(.*\)mod_proxy.so@LoadModule\1mod_proxy.so@' $Install_Apache_Path/conf/httpd.conf # PHP-FPM / Proxy
    sed -i 's@^#LoadModule\(.*\)mod_proxy_http.so@LoadModule\1mod_proxy_http.so@' $Install_Apache_Path/conf/httpd.conf # Proxy
    sed -i 's@^#LoadModule\(.*\)mod_proxy_fcgi.so@LoadModule\1mod_proxy_fcgi.so@' $Install_Apache_Path/conf/httpd.conf # PHP-FPM
    sed -i 's@^#LoadModule\(.*\)mod_ssl.so@LoadModule\1mod_ssl.so@' $Install_Apache_Path/conf/httpd.conf # HTTPS
    sed -i 's@^#LoadModule\(.*\)mod_http2.so@LoadModule\1mod_http2.so@' $Install_Apache_Path/conf/httpd.conf # HTTPS
    sed -i 's@^#LoadModule\(.*\)mod_rewrite.so@LoadModule\1mod_rewrite.so@' $Install_Apache_Path/conf/httpd.conf
    echo -e "\033[32m模块开启成功\033[0m"

    sed -i "s@^User daemon@User $Low_User@" $Install_Apache_Path/conf/httpd.conf
    sed -i "s@^Group daemon@Group $Low_Group@" $Install_Apache_Path/conf/httpd.conf
    sed -i 's/^ServerAdmin you@example.com/ServerAdmin administrator@ttionya.com/' $Install_Apache_Path/conf/httpd.conf
    sed -i 's@^#ServerName www.example.com:80@ServerName localhost@' $Install_Apache_Path/conf/httpd.conf
    echo -e "\033[32m用户设置成功\033[0m"

    # MIMEType
    sed -i "s@AddType\(.*\)Z@AddType\1Z\n    AddType application/x-httpd-php .php .phtml\n    AddType application/x-httpd-php-source .phps@" $Install_Apache_Path/conf/httpd.conf
    sed -i 's@DirectoryIndex index.html@DirectoryIndex index.php index.html@' $Install_Apache_Path/conf/httpd.conf
    echo -e "\033[32mMIMEType 设置成功\033[0m"

    # Document
    sed -i "s@^DocumentRoot.*@DocumentRoot \"$WWW_Path\"@" $Install_Apache_Path/conf/httpd.conf
    sed -i "s@^<Directory \"$Install_Apache_Path/htdocs\">@<Directory \"$WWW_Path\">@" $Install_Apache_Path/conf/httpd.conf
    sed -i 's@Options Indexes FollowSymLinks@Options +Includes -Indexes@' $Install_Apache_Path/conf/httpd.conf
    echo -e "\033[32m文档设置成功\033[0m"

    # Logs
    sed -i "s@^ErrorLog \"logs/error_log\"@ErrorLog \"| $Install_Apache_Path/bin/rotatelogs $Install_Apache_Path/logs/error_log_%Y%m%d.log 86400\"@" $Install_Apache_Path/conf/httpd.conf
    sed -i "s@CustomLog \"logs/access_log\" common@#CustomLog \"logs/access_log\" common@" $Install_Apache_Path/conf/httpd.conf
    sed -i "s@#CustomLog \"logs/access_log\" combined@CustomLog \"| $Install_Apache_Path/bin/rotatelogs $Install_Apache_Path/logs/access_log_%Y%m%d.log 86400\" combined@" $Install_Apache_Path/conf/httpd.conf
    echo -e "\033[32m日志设置成功\033[0m"

    # Extra Config File
    mkdir $Install_Apache_Path/conf/extra/vhost
    sed -i 's@^#Include conf/extra/httpd-vhosts.conf@Include conf/extra/vhost/*.conf@' $Install_Apache_Path/conf/httpd.conf
    sed -i 's@^#Include conf/extra/httpd-mpm.conf@Include conf/extra/httpd-mpm.conf@' $Install_Apache_Path/conf/httpd.conf
    sed -i 's@^#Include conf/extra/httpd-default.conf@Include conf/extra/httpd-default.conf@' $Install_Apache_Path/conf/httpd.conf
    sed -i 's@^#Include conf/extra/httpd-ssl.conf@Include conf/extra/httpd-ssl.conf@' $Install_Apache_Path/conf/httpd.conf
    cat >> $Install_Apache_Path/conf/httpd.conf << EOF
# deflate
Include conf/extra/httpd-deflate.conf

<FilesMatch \.php$>
    SetHandler "proxy:unix:/var/run/php-fpm.sock|fcgi://localhost:9000"
</FilesMatch>
EOF
    echo -e "\033[32m额外模块开启成功\033[0m"

    # vhost/*.conf
    rm -f $Install_Apache_Path/conf/extra/httpd-vhosts.conf
    cat > $Install_Apache_Path/conf/extra/vhost/80.localhost.conf << EOF
<VirtualHost *:80>
    DocumentRoot "$WWW_Path/default/"
    ServerName localhost
#    ProxyRequests Off
#    ProxyPassMatch ^/(.*\.php(/.*)?)$ unix:/var/run/php-fpm.sock|fcgi://localhost:9000/data/www/default/
    <Directory "$WWW_Path/default/">
        Options +Includes -Indexes
        Require all granted
        AllowOverride All
    </Directory>
    ErrorLog "| $Install_Apache_Path/bin/rotatelogs $Install_Apache_Path/logs/80.localhost.error.%Y%m%d.log 86400"
    CustomLog "| $Install_Apache_Path/bin/rotatelogs $Install_Apache_Path/logs/80.localhost.access.%Y%m%d.log 86400" combined
</VirtualHost>
EOF
    echo -e "\033[32mhttpd-vhost 设置成功\033[0m"

    # httpd-default
    sed -i 's@Timeout 60@Timeout 120@' $Install_Apache_Path/conf/extra/httpd-default.conf
    sed -i 's@MaxKeepAliveRequests 100@MaxKeepAliveRequests 1024@' $Install_Apache_Path/conf/extra/httpd-default.conf
    sed -i 's@^ServerTokens\(.*\)@ServerTokens Prod@' $Install_Apache_Path/conf/extra/httpd-default.conf
    sed -i 's@^ServerSignature\(.*\)@ServerSignature Off@' $Install_Apache_Path/conf/extra/httpd-default.conf
    echo -e "\033[32mhttpd-default 设置成功\033[0m"

    # httpd-ssl
    sed -i '/^Listen 443/a\
Protocols h2 http/1.1' $Install_Apache_Path/conf/extra/httpd-ssl.conf
    sed -i '/SSL Virtual Host Context/,$d' $Install_Apache_Path/conf/extra/httpd-ssl.conf
    echo -e "\033[32mhttpd-ssl 设置成功\033[0m"

    # http-deflate
    rm -f $Install_Apache_Path/conf/extra/httpd-deflate.conf
    cat > $Install_Apache_Path/conf/extra/httpd-deflate.conf << EOF
<IfModule mod_deflate.c>
    SetOutputFilter DEFLATE
    SetEnvIfNoCase Request_URI .(?:gif|jpe?g|png|webp)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI .(?:exe|t?gz|zip|bz2|sit|rar|7z|xz)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI .(?:pdf|mov|avi|mp3|mp4|rm)$ no-gzip dont-vary
    AddOutputFilterByType DEFLATE text/html text/css text/plain text/xml text/javascript
    AddOutputFilterByType DEFLATE application/x-httpd-php application/x-javascript application/javascript
</IfModule>
EOF
    echo -e "\033[32mhttpd-deflate 设置成功\033[0m"

    # Firewall
    if which firewall-cmd > /dev/null 2>&1; then
        firewall-cmd --add-service=http
        firewall-cmd --permanent --add-service=http
        firewall-cmd --add-service=https
        firewall-cmd --permanent --add-service=https
        echo ""
        echo -e "\033[32mfirewalld 防火墙已开启 80 443 端口\033[0m"
    else
        iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
        iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
        /sbin/service iptables save
        /etc/init.d/iptables restart
        echo ""
        echo -e "\033[32miptables 防火墙已开启 80 443 端口\033[0m"
    fi

    echo -e "\033[32m===================== Apache 配置完成，开始进行测试 ====================\033[0m"

    echo "Success" > $WWW_Path/default/index.html
    echo ""
    systemctl restart httpd.service
    Index_Content=`curl http://localhost/`
    if [[ $Index_Content == Success ]]; then
        echo -e "\033[32m测试通过\033[0m"
    else
        echo -e "\033[31m测试失败\033[0m"
    fi
}

# Show Install Information
clear
echo -e "\033[34m##########################################################\033[0m"
echo -e "\033[34m# Auto Install Script for Apache 2.4 With HTTP/2         #\033[0m"
echo -e "\033[34m# System Required:  CentOS / RedHat 7.X                  #\033[0m"
echo -e "\033[34m# Author: ttionya                                        #\033[0m"
echo -e "\033[34m##########################################################\033[0m"
echo ""
echo -e "\033[33m将安装 Apache $Latest_Apache_Ver, APR $Latest_APR_Ver, APR-util $Latest_APR_Util_Ver\033[0m"
echo ""
echo -e "\033[33m将安装 PCRE $Latest_PCRE_Ver\033[0m"
echo ""
echo -e "\033[33m将安装 nghttp2 $Latest_nghttp2_Ver\033[0m"
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
    install_apache
else
    echo ""
    echo -e "\033[34mApache 安装被取消，未作任何更改...\033[0m"
fi

# Ver1.0.1
# - 添加 Proxy 和 SSL 支持
#
# Ver1.0.2
# - 修改 sock 文件位置，解决 systemctl 启动 php-fpm 出现无法找到 sock 文件的情况