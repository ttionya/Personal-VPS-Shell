#!/usr/bin/env bash

# Version: 2.0.2
# Author: ttionya


################### Customer Setting ####################
# 下载地址
DOWNLOAD_PATH="/usr/local/src"
# 低权限用户和组
LOW_LEVEL_USER="www"
LOW_LEVEL_GROUP="www"
# 默认网站路径
WWW_PATH="/data/www"
# PCRE 1 版本号
LATEST_PCRE_VERSION="8.43"
# nghttp2 版本号
LATEST_NGHTTP2_VERSION="1.38.0"
# OpenSSL 1.1.1 版本号
LATEST_OPENSSL_VERSION="1.1.1b"
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# Apache 安装路径
INSTALL_APACHE_PATH="/usr/local/apache"
# PCRE 安装路径
INSTALL_PCRE_PATH="/usr/local/pcre"
# nghttp2 安装路径
INSTALL_NGHTTP2_PATH="/usr/local/nghttp2"
# OpenSSL 安装路径
INSTALL_OPENSSL_PATH="/usr/local/openssl"


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
    # Check Apache Path
    if [[ -d ${INSTALL_APACHE_PATH} ]]; then
        color yellow "警告：Apache 目录 ${INSTALL_APACHE_PATH} 已存在"
        color yellow "继续下一步会立即删除已存在的目录，是否要继续 ？ (y/n)"
        read -p "(Default: n):" CHECK_DEL_INSTALLED

        # Check Delete Installed Path
        if [[ $(echo ${CHECK_DEL_INSTALLED:-n} | tr [a-z] [A-Z]) == Y ]]; then
            pkill -9 httpd
            rm -rf ${INSTALL_APACHE_PATH}
            color green "删除成功"
        else
            color ""
            color blue "Apache 安装被取消..."
            exit 0
        fi
    fi
}

# Get Software Version Information
function get_version_info() {
    color ""
    color blue "正在获取软件信息..."
    color ""

    # Check APR/APR-util Version
    APR_DOWNLOAD_URL="$(curl --retry 3 -s https://www.apache.org/dyn/closer.cgi | grep -oE "<strong>[^<]*</strong>" | head -n 1 | sed "s@<strong>\(.*\)</strong>@\1@g")/apr/"
    APR_DOWNLOAD_LIST="$(curl --retry 3 -s ${APR_DOWNLOAD_URL})"
    LATEST_APR_DOWNLOAD_URL="${APR_DOWNLOAD_URL}$(echo ${APR_DOWNLOAD_LIST} | grep -oP "apr-1.[6-9][^\"]*.tar.gz" | tail -n 1)"
    LATEST_APR_VERSION="$(echo ${LATEST_APR_DOWNLOAD_URL} | grep -oE "([0-9].)*[0-9]")"
    LATEST_APR_UTIL_DOWNLOAD_URL="${APR_DOWNLOAD_URL}$(echo ${APR_DOWNLOAD_LIST} | grep -oP "apr-util-1.[6-9][^\"]*.tar.gz" | tail -n 1)"
    LATEST_APR_UTIL_VERSION="$(echo ${LATEST_APR_UTIL_DOWNLOAD_URL} | grep -oE "([0-9].)*[0-9]")"

    # Check Apache Version
    LATEST_APACHE_DOWNLOAD_URL="$(curl --retry 3 -s http://httpd.apache.org/download.cgi | grep -oE "http[s]?://.*//httpd/httpd-2.4.[0-9]*.tar.gz")"
    LATEST_APACHE_VERSION="$(echo ${LATEST_APACHE_DOWNLOAD_URL} | grep -oE "2.4.[0-9]*")"

    # Check CPU Number
    CPU_NUM=$(grep -c 'processor' /proc/cpuinfo)
}

# Remove YUM Version Apache
function remove_yum_apache() {
    rpm -e --nodeps httpd
    yum -y remove httpd
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

# Install PCRE
function install_pcre() {
    color ""
    cd ${DOWNLOAD_PATH}

    DIR_SOURCE_PCRE="pcre-${LATEST_PCRE_VERSION}"
    FILE_SOURCE_PCRE="pcre-${LATEST_PCRE_VERSION}.tar.gz"

    # Clean UP
    rm -rf ${DIR_SOURCE_PCRE}

    # Download
    if [[ ! -s ${FILE_SOURCE_PCRE} ]]; then
        wget -c -t3 -T60 "https://ftp.pcre.org/pub/pcre/${FILE_SOURCE_PCRE}"
        if [[ $? != 0 ]]; then
            rm -rf ${FILE_SOURCE_PCRE}
            color ""
            color red "错误：PCRE 下载失败"
            exit 1
        fi
    fi

    # Extract
    tar -zxf ${FILE_SOURCE_PCRE}
    cd ${DIR_SOURCE_PCRE}

    # Configure
    ./configure --prefix=${INSTALL_PCRE_PATH}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：PCRE 配置失败"
        exit 1
    fi

    # Make
    make -j ${CPU_NUM}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：PCRE 编译失败"
        exit 1
    fi

    # Backup
    if [[ -d ${INSTALL_PCRE_PATH} ]]; then
        rm -rf ${INSTALL_PCRE_PATH}.bak
        mv ${INSTALL_PCRE_PATH} ${INSTALL_PCRE_PATH}.bak
    fi

    # Install
    make install
    if [[ $? != 0 ]]; then
        rm -rf ${INSTALL_PCRE_PATH}
        mv ${INSTALL_PCRE_PATH}.bak ${INSTALL_PCRE_PATH}
        color ""
        color red "错误：PCRE 安装失败"
        exit 1
    fi

    # Clean Up
    cd ${DOWNLOAD_PATH}
    rm -rf ${DIR_SOURCE_PCRE}

    # Result
    color ""
    color green "===================== PCRE 安装完成 ====================="
    color ""
}

# Check PCRE
function check_pcre() {
    color ""
    BIN_PCRE="${INSTALL_PCRE_PATH}/bin/pcre-config"

    if which ${BIN_PCRE} > /dev/null 2>&1; then
        INSTALLED_PCRE_VERSION="$(${BIN_PCRE} --version)"

        color yellow "PCRE ${INSTALLED_PCRE_VERSION} -> PCRE ${LATEST_PCRE_VERSION}，确认安装？ (y/n)"
        read -p "(Default: y):" CHECK_REINSTALL_PCRE

        # Check Reinstall
        if [[ $(echo ${CHECK_REINSTALL_PCRE:-y} | tr [a-z] [A-Z]) == Y ]]; then
            NEED_INSTALL_PCRE=1
        else
            NEED_INSTALL_PCRE=0
        fi
    else
        NEED_INSTALL_PCRE=1
    fi

    if [[ ${NEED_INSTALL_PCRE} == 1 ]]; then
        install_pcre
    else
        color ""
        color yellow "跳过 PCRE ${LATEST_PCRE_VERSION} 安装..."
    fi
}

# Install nghttp2
function install_nghttp2() {
    color ""
    cd ${DOWNLOAD_PATH}

    DIR_SOURCE_NGHTTP2="nghttp2-${LATEST_NGHTTP2_VERSION}"
    FILE_SOURCE_NGHTTP2="nghttp2-${LATEST_NGHTTP2_VERSION}.tar.gz"

    # Clean UP
    rm -rf ${DIR_SOURCE_NGHTTP2}

    # Download
    if [[ ! -s ${FILE_SOURCE_NGHTTP2} ]]; then
        wget -c -t3 -T60 "https://github.com/nghttp2/nghttp2/releases/download/v${LATEST_NGHTTP2_VERSION}/${FILE_SOURCE_NGHTTP2}" -O ${FILE_SOURCE_NGHTTP2}
        if [[ $? != 0 ]]; then
            rm -rf ${FILE_SOURCE_NGHTTP2}
            color ""
            color red "错误：nghttp2 下载失败"
            exit 1
        fi
    fi

    # Extract
    tar -zxf ${FILE_SOURCE_NGHTTP2}
    cd ${DIR_SOURCE_NGHTTP2}

    # Configure
    ./configure --prefix=${INSTALL_NGHTTP2_PATH}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：nghttp2 配置失败"
        exit 1
    fi

    # Make
    make -j ${CPU_NUM}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：nghttp2 编译失败"
        exit 1
    fi

    # Backup
    if [[ -d ${INSTALL_NGHTTP2_PATH} ]]; then
        rm -rf ${INSTALL_NGHTTP2_PATH}.bak
        mv ${INSTALL_NGHTTP2_PATH} ${INSTALL_NGHTTP2_PATH}.bak
    fi

    # Install
    make install
    if [[ $? != 0 ]]; then
        rm -rf ${INSTALL_NGHTTP2_PATH}
        mv ${INSTALL_NGHTTP2_PATH}.bak ${INSTALL_NGHTTP2_PATH}
        color ""
        color red "错误：nghttp2 安装失败"
        exit 1
    fi

    # Clean Up
    cd ${DOWNLOAD_PATH}
    rm -rf ${DIR_SOURCE_NGHTTP2}

    # Result
    color ""
    color green "===================== nghttp2 安装完成 ====================="
    color ""
}

# Check nghttp2
function check_nghttp2() {
    color ""
    BIN_NGHTTP2="${INSTALL_NGHTTP2_PATH}/include/nghttp2/nghttp2ver.h"

    if [[ -f ${BIN_NGHTTP2} ]]; then
        INSTALLED_NGHTTP2_VERSION="$(grep 'NGHTTP2_VERSION ' ${BIN_NGHTTP2} | awk '{print $3}' | grep -oP "[0-9.]*")"

        color yellow "nghttp2 ${INSTALLED_NGHTTP2_VERSION} -> nghttp2 ${LATEST_NGHTTP2_VERSION}，确认安装？ (y/n)"
        read -p "(Default: y):" CHECK_REINSTALL_NGHTTP2

        # Check Reinstall
        if [[ $(echo ${CHECK_REINSTALL_NGHTTP2:-y} | tr [a-z] [A-Z]) == Y ]]; then
            NEED_INSTALL_NGHTTP2=1
        else
            NEED_INSTALL_NGHTTP2=0
        fi
    else
        NEED_INSTALL_NGHTTP2=1
    fi

    if [[ ${NEED_INSTALL_NGHTTP2} == 1 ]]; then
        install_nghttp2
    else
        color ""
        color yellow "跳过 nghttp2 ${LATEST_NGHTTP2_VERSION} 安装..."
    fi
}

# Install OpenSSL
function install_openssl() {
    color ""
    cd ${DOWNLOAD_PATH}

    DIR_SOURCE_OPENSSL="openssl-${LATEST_OPENSSL_VERSION}"
    FILE_SOURCE_OPENSSL="openssl-${LATEST_OPENSSL_VERSION}.tar.gz"

    # Clean UP
    rm -rf ${DIR_SOURCE_OPENSSL}

    # Download
    if [[ ! -s ${FILE_SOURCE_OPENSSL} ]]; then
        wget -c -t3 -T60 "https://www.openssl.org/source/${FILE_SOURCE_OPENSSL}" -O ${FILE_SOURCE_OPENSSL}
        if [[ $? != 0 ]]; then
            rm -rf ${FILE_SOURCE_OPENSSL}
            color ""
            color red "错误：OpenSSL 下载失败"
            exit 1
        fi
    fi

    # Extract
    tar -zxf ${FILE_SOURCE_OPENSSL}
    cd ${DIR_SOURCE_OPENSSL}

    # Configure
    ./config --prefix=${INSTALL_OPENSSL_PATH} zlib-dynamic shared
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：OpenSSL 配置失败"
        exit 1
    fi

    # Make
    make -j ${CPU_NUM}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：OpenSSL 编译失败"
        exit 1
    fi

    # Test
    make test
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：OpenSSL 测试失败"
        exit 1
    fi

    # Backup
    if [[ -d ${INSTALL_OPENSSL_PATH} ]]; then
        rm -rf ${INSTALL_OPENSSL_PATH}.bak
        mv ${INSTALL_OPENSSL_PATH} ${INSTALL_OPENSSL_PATH}.bak
    fi

    # Install
    make install
    if [[ $? != 0 ]]; then
        rm -rf ${INSTALL_OPENSSL_PATH}
        mv ${INSTALL_OPENSSL_PATH}.bak ${INSTALL_OPENSSL_PATH}
        color ""
        color red "错误：OpenSSL 安装失败"
        exit 1
    fi

    # Clean Up
    cd ${DOWNLOAD_PATH}
    rm -rf ${DIR_SOURCE_OPENSSL}

    # Link
    ln -fns ${INSTALL_OPENSSL_PATH}/lib/libssl.so.1.1 /usr/lib64/
    ln -fns ${INSTALL_OPENSSL_PATH}/lib/libcrypto.so.1.1 /usr/lib64/

    # Result
    color ""
    color green "===================== OpenSSL 安装完成 ====================="
    color ""
}

# Check OpenSSL
function check_openssl() {
    color ""
    BIN_OPENSSL="${INSTALL_OPENSSL_PATH}/bin/openssl"

    if which ${BIN_OPENSSL} > /dev/null 2>&1; then
        INSTALLED_OPENSSL_VERSION="$(${BIN_OPENSSL} version | awk '{print $2}')"

        color yellow "OpenSSL ${INSTALLED_OPENSSL_VERSION} -> OpenSSL ${LATEST_OPENSSL_VERSION}，确认安装？ (y/n)"
        read -p "(Default: y):" CHECK_REINSTALL_OPENSSL

        # Check Reinstall
        if [[ $(echo ${CHECK_REINSTALL_OPENSSL:-y} | tr [a-z] [A-Z]) == Y ]]; then
            NEED_INSTALL_OPENSSL=1
        else
            NEED_INSTALL_OPENSSL=0
        fi
    else
        NEED_INSTALL_OPENSSL=1
    fi

    if [[ ${NEED_INSTALL_OPENSSL} == 1 ]]; then
        install_openssl
    else
        color ""
        color yellow "跳过 OpenSSL ${LATEST_OPENSSL_VERSION} 安装..."
    fi
}

# Install Apache
function install_apache() {
    color ""
    cd ${DOWNLOAD_PATH}

    DIR_SOURCE_APR="apr-${LATEST_APR_VERSION}"
    DIR_SOURCE_APR_UTIL="apr-util-${LATEST_APR_UTIL_VERSION}"
    DIR_SOURCE_APACHE="httpd-${LATEST_APACHE_VERSION}"
    FILE_SOURCE_APR="apr-${LATEST_APR_VERSION}.tar.gz"
    FILE_SOURCE_APR_UTIL="apr-util-${LATEST_APR_UTIL_VERSION}.tar.gz"
    FILE_SOURCE_APACHE="httpd-${LATEST_APACHE_VERSION}.tar.gz"

    # Clean UP
    rm -rf ${DIR_SOURCE_APR}
    rm -rf ${DIR_SOURCE_APR_UTIL}
    rm -rf ${DIR_SOURCE_APACHE}

    # Download
    if [[ ! -s ${FILE_SOURCE_APR} ]]; then
        wget -c -t3 -T60 "${LATEST_APR_DOWNLOAD_URL}"
        if [[ $? != 0 ]]; then
            rm -rf ${FILE_SOURCE_APR}
            color ""
            color red "错误：APR 下载失败"
            exit 1
        fi
    fi
    if [[ ! -s ${FILE_SOURCE_APR_UTIL} ]]; then
        wget -c -t3 -T60 "${LATEST_APR_UTIL_DOWNLOAD_URL}"
        if [[ $? != 0 ]]; then
            rm -rf ${FILE_SOURCE_APR_UTIL}
            color ""
            color red "错误：APR-util 下载失败"
            exit 1
        fi
    fi
    if [[ ! -s ${FILE_SOURCE_APACHE} ]]; then
        wget -c -t3 -T60 "${LATEST_APACHE_DOWNLOAD_URL}"
        if [[ $? != 0 ]]; then
            rm -rf ${FILE_SOURCE_APACHE}
            color ""
            color red "错误：Apache 下载失败"
            exit 1
        fi
    fi

    # Extract
    tar -zxf ${FILE_SOURCE_APR}
    tar -zxf ${FILE_SOURCE_APR_UTIL}
    tar -zxf ${FILE_SOURCE_APACHE}
    color ""
    color green "源码包已解压"

    # Move APR
    mv ${DIR_SOURCE_APR} ${DIR_SOURCE_APACHE}/srclib/apr
    mv ${DIR_SOURCE_APR_UTIL} ${DIR_SOURCE_APACHE}/srclib/apr-util

    cd ${DIR_SOURCE_APACHE}

    # Configure
    ./configure \
    --prefix=${INSTALL_APACHE_PATH} \
    --with-pcre=${INSTALL_PCRE_PATH} \
    --with-mpm=event \
    --with-included-apr \
    --with-ssl=${INSTALL_OPENSSL_PATH} \
    --with-nghttp2=${INSTALL_NGHTTP2_PATH} \
    --enable-modules=all \
    --enable-mods-shared=all \
    --enable-mpms-shared=all \
    --enable-so \
    --enable-ssl \
    --enable-http2 \
    --enable-proxy-http2
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：Apache 配置失败"
        exit 1
    fi

    # Make
    make -j ${CPU_NUM}
    if [[ $? != 0 ]]; then
        color ""
        color red "错误：Apache 编译失败"
        exit 1
    fi

    # Install
    make install
    if [[ $? != 0 ]]; then
        rm -rf ${INSTALL_APACHE_PATH}
        color ""
        color red "错误：Apache 安装失败"
        exit 1
    fi

    # Clean Up
    cd ${DOWNLOAD_PATH}
    rm -rf ${DIR_SOURCE_APACHE}

    # Result
    color ""
    color green "===================== Apache 安装完成 ====================="
    color ""
}

# Configure Apache
function configure_apache() {
    # Add Systemd Script
    cat > /usr/lib/systemd/system/httpd.service << EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd.service(8)

[Service]
Type=simple
# EnvironmentFile=/etc/sysconfig/httpd
Environment=LANG=C

ExecStart=${INSTALL_APACHE_PATH}/bin/httpd \$OPTIONS -DFOREGROUND
ExecReload=${INSTALL_APACHE_PATH}/bin/httpd \$OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload

    # Auto Start
    systemctl enable httpd.service
    if [[ $? != 0 ]]; then
        color yellow "警告：httpd 设置开机自启动失败"
    else
        color green "httpd 设置开机自启动成功"
    fi

    # Link Commands
    ln -fs ${INSTALL_APACHE_PATH}/bin/httpd /usr/local/bin/
    ln -fs ${INSTALL_APACHE_PATH}/bin/apachectl /usr/local/bin/

    # Link Logs
    ln -fns ${INSTALL_APACHE_PATH}/logs /var/log/httpd

    # Create User And Group
    groupadd -f ${LOW_LEVEL_GROUP}
    if id -u ${LOW_LEVEL_USER} > /dev/null 2>&1; then
        color yellow "用户已存在，跳过"
    else
        useradd -g ${LOW_LEVEL_GROUP} -s /sbin/nologin ${LOW_LEVEL_USER}
    fi

    # Create WWW Directory
    mkdir -p ${WWW_PATH}/default
    chmod -R 755 ${WWW_PATH}

    # Set httpd.conf File
    FILE_CONF_HTTPD="${INSTALL_APACHE_PATH}/conf/httpd.conf"
    cp -f ${FILE_CONF_HTTPD} ${FILE_CONF_HTTPD}.bak
    # Modules
    sed -i 's@^#LoadModule\(.*\)mod_socache_shmcb.so@LoadModule\1mod_socache_shmcb.so@' ${FILE_CONF_HTTPD} # HTTPS
    sed -i 's@^#LoadModule\(.*\)mod_deflate.so@LoadModule\1mod_deflate.so@' ${FILE_CONF_HTTPD} # GZip
    sed -i 's@^#LoadModule\(.*\)mod_expires.so@LoadModule\1mod_expires.so@' ${FILE_CONF_HTTPD} # Cache
    sed -i 's@^#LoadModule\(.*\)mod_remoteip.so@LoadModule\1mod_remoteip.so@' ${FILE_CONF_HTTPD} # Proxy
    sed -i 's@^#LoadModule\(.*\)mod_proxy.so@LoadModule\1mod_proxy.so@' ${FILE_CONF_HTTPD} # PHP-FPM / Proxy
    sed -i 's@^#LoadModule\(.*\)mod_proxy_http.so@LoadModule\1mod_proxy_http.so@' ${FILE_CONF_HTTPD} # Proxy
    sed -i 's@^#LoadModule\(.*\)mod_proxy_http2.so@LoadModule\1mod_proxy_http2.so@' ${FILE_CONF_HTTPD} # HTTPS / Proxy
    sed -i 's@^#LoadModule\(.*\)mod_proxy_fcgi.so@LoadModule\1mod_proxy_fcgi.so@' ${FILE_CONF_HTTPD} # PHP-FPM
    sed -i 's@^#LoadModule\(.*\)mod_ssl.so@LoadModule\1mod_ssl.so@' ${FILE_CONF_HTTPD} # HTTPS
    sed -i 's@^#LoadModule\(.*\)mod_http2.so@LoadModule\1mod_http2.so@' ${FILE_CONF_HTTPD} # HTTPS
    sed -i 's@^#LoadModule\(.*\)mod_rewrite.so@LoadModule\1mod_rewrite.so@' ${FILE_CONF_HTTPD} # Rewrite
    color green "模块开启成功"
    # User
    sed -i "s@^User daemon@User ${LOW_LEVEL_USER}@" ${FILE_CONF_HTTPD}
    sed -i "s@^Group daemon@Group ${LOW_LEVEL_GROUP}@" ${FILE_CONF_HTTPD}
    sed -i 's/^ServerAdmin you@example.com/ServerAdmin administrator@ttionya.com/' ${FILE_CONF_HTTPD}
    sed -i 's@^#ServerName www.example.com:80@ServerName localhost@' ${FILE_CONF_HTTPD}
    color green "用户设置成功"
    # MIMEType
    sed -i "s@AddType\(.*\)Z@AddType\1Z\n    AddType application/x-httpd-php .php@" ${FILE_CONF_HTTPD}
    sed -i 's@DirectoryIndex index.html@DirectoryIndex index.php index.html@' ${FILE_CONF_HTTPD}
    color green "MIMEType 设置成功"
    # Document
    sed -i "s@^DocumentRoot.*@DocumentRoot \"${WWW_PATH}\"@" ${FILE_CONF_HTTPD}
    sed -i "s@^<Directory \"${INSTALL_APACHE_PATH}/htdocs\">@<Directory \"${WWW_PATH}\">@" ${FILE_CONF_HTTPD}
    sed -i 's@Options Indexes FollowSymLinks@Options +Includes -Indexes@' ${FILE_CONF_HTTPD}
    color green "文档设置成功"
    # Logs
    sed -i "s@^ErrorLog \"logs/error_log\"@ErrorLog \"| ${INSTALL_APACHE_PATH}/bin/rotatelogs ${INSTALL_APACHE_PATH}/logs/error_log_%Y%m%d.log 86400\"@" ${FILE_CONF_HTTPD}
    sed -i "s@CustomLog \"logs/access_log\" common@#CustomLog \"logs/access_log\" common@" ${FILE_CONF_HTTPD}
    sed -i "s@#CustomLog \"logs/access_log\" combined@CustomLog \"| ${INSTALL_APACHE_PATH}/bin/rotatelogs ${INSTALL_APACHE_PATH}/logs/access_log_%Y%m%d.log 86400\" combined@" ${FILE_CONF_HTTPD}
    color green "日志设置成功"
    # Extra Config File
    mkdir ${INSTALL_APACHE_PATH}/conf/extra/vhost
    sed -i 's@^#Include conf/extra/httpd-vhosts.conf@Include conf/extra/vhost/*.conf@' ${FILE_CONF_HTTPD}
    sed -i 's@^#Include conf/extra/httpd-mpm.conf@Include conf/extra/httpd-mpm.conf@' ${FILE_CONF_HTTPD}
    sed -i 's@^#Include conf/extra/httpd-default.conf@Include conf/extra/httpd-default.conf@' ${FILE_CONF_HTTPD}
    sed -i 's@^#Include conf/extra/httpd-ssl.conf@Include conf/extra/httpd-ssl.conf@' ${FILE_CONF_HTTPD}
    cat >> ${FILE_CONF_HTTPD} << EOF
# deflate
Include conf/extra/httpd-deflate.conf

<FilesMatch \.php$>
    SetHandler "proxy:unix:/var/run/php-fpm.sock|fcgi://localhost:9000"
</FilesMatch>
EOF
    color green "额外模块开启成功"

    # Set vhost/*.conf File
    cat > ${INSTALL_APACHE_PATH}/conf/extra/vhost/80.localhost.conf << EOF
<VirtualHost *:80>
    DocumentRoot "${WWW_PATH}/default/"
    ServerName localhost

#    ProxyRequests Off
#    ProxyPassMatch ^/(.*\.php(/.*)?)$ unix:/var/run/php-fpm.sock|fcgi://localhost:9000/data/www/default/

    <Directory "${WWW_PATH}/default/">
        Options +Includes -Indexes
        Require all granted
        AllowOverride All
    </Directory>

    ErrorLog "| ${INSTALL_APACHE_PATH}/bin/rotatelogs ${INSTALL_APACHE_PATH}/logs/80.localhost.error.%Y%m%d.log 86400"
    CustomLog "| ${INSTALL_APACHE_PATH}/bin/rotatelogs ${INSTALL_APACHE_PATH}/logs/80.localhost.access.%Y%m%d.log 86400" combined
</VirtualHost>
EOF
    cat > ${INSTALL_APACHE_PATH}/conf/extra/vhost/443.localhost.conf << EOF
#<VirtualHost *:443>
#    DocumentRoot "${WWW_PATH}/default/"
#    ServerName localhost:443
#
#    <Directory "${WWW_PATH}/default/">
#        Options +Includes -Indexes
#        Require all granted
#        AllowOverride All
#    </Directory>
#
#    # 开关
#    # ProxyRequests Off
#    SSLEngine On
#    # SSLProxyEngine On
#
#    # 证书
#    SSLCertificateFile "${INSTALL_APACHE_PATH}/conf/cert/cert.crt"
#    SSLCertificateKeyFile "${INSTALL_APACHE_PATH}/conf/cert/server.key"
#    SSLCertificateChainFile "${INSTALL_APACHE_PATH}/conf/cert/chaincer.crt"
#
#    # RemoteIPHeader X-Forwarded-For
#
#    <FilesMatch "\.(cgi|shtml|phtml|php)$">
#        SSLOptions +StdEnvVars
#    </FilesMatch>
#    <Directory "${INSTALL_APACHE_PATH}/cgi-bin">
#        SSLOptions +StdEnvVars
#    </Directory>
#
#    ErrorLog "| ${INSTALL_APACHE_PATH}/bin/rotatelogs ${INSTALL_APACHE_PATH}/logs/443.localhost.error.%Y%m%d.log 86400"
#    CustomLog "| ${INSTALL_APACHE_PATH}/bin/rotatelogs ${INSTALL_APACHE_PATH}/logs/443.localhost.access.%Y%m%d.log 86400" combined
#</VirtualHost>
EOF
    color green "httpd-vhost 设置成功"

    # Set httpd-default.conf File
    FILE_CONF_HTTPD_DEFAULT="${INSTALL_APACHE_PATH}/conf/extra/httpd-default.conf"
    sed -i 's@Timeout 60@Timeout 120@' ${FILE_CONF_HTTPD_DEFAULT}
    sed -i 's@MaxKeepAliveRequests 100@MaxKeepAliveRequests 1024@' ${FILE_CONF_HTTPD_DEFAULT}
    sed -i 's@^ServerTokens\(.*\)@ServerTokens Prod@' ${FILE_CONF_HTTPD_DEFAULT}
    sed -i 's@^ServerSignature\(.*\)@ServerSignature Off@' ${FILE_CONF_HTTPD_DEFAULT}
    color green "httpd-default 设置成功"

    # Set httpd-ssl.conf File
    FILE_CONF_HTTPD_SSL="${INSTALL_APACHE_PATH}/conf/extra/httpd-ssl.conf"
    sed -i '/^Listen 443/a\
Protocols h2 http/1.1' ${FILE_CONF_HTTPD_SSL}
    sed -i '/SSL Virtual Host Context/,$d' ${FILE_CONF_HTTPD_SSL}
    color green "httpd-ssl 设置成功"

    # Set http-deflate.conf File
    FILE_CONF_HTTPD_DEFLATE="${INSTALL_APACHE_PATH}/conf/extra/httpd-deflate.conf"
    cat > ${FILE_CONF_HTTPD_DEFLATE} << EOF
<IfModule mod_deflate.c>
    SetOutputFilter DEFLATE
    SetEnvIfNoCase Request_URI .(?:gif|jpe?g|png|webp)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI .(?:exe|t?gz|zip|bz2|sit|rar|7z|xz)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI .(?:pdf|mov|avi|mp3|mp4|rm)$ no-gzip dont-vary
    AddOutputFilterByType DEFLATE text/html text/css text/plain text/xml text/javascript
    AddOutputFilterByType DEFLATE application/x-httpd-php application/x-javascript application/javascript
</IfModule>
EOF
    color green "httpd-deflate 设置成功"

    # Result
    color ""
    color green "===================== Apache 配置完成 ====================="
    color ""
}

# Configure Firewall
function configure_firewall() {
    if which firewall-cmd > /dev/null 2>&1; then
        firewall-cmd --add-service=http
        firewall-cmd --permanent --add-service=http
        firewall-cmd --add-service=https
        firewall-cmd --permanent --add-service=https
        color ""
        color green "firewalld 防火墙已开启 80 443 端口"
    else
        iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
        iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
        /sbin/service iptables save
        /etc/init.d/iptables restart
        color ""
        color green "iptables 防火墙已开启 80 443 端口"
    fi
}

# Test Apache
function test_apache() {
    echo "Success" > ${WWW_PATH}/default/index.html

    systemctl restart httpd.service

    INDEX_CONTENT="$(curl http://localhost/)"
    if [[ ${INDEX_CONTENT} == Success ]]; then
        color green "测试通过"
    else
        color red "测试失败"
    fi
}

# Main
function main() {
    color ""
    color blue "===================== Apache 安装程序启动 ====================="

    remove_yum_apache
    install_dependencies

    check_pcre
    check_nghttp2
    check_openssl
    install_apache

    configure_apache
    configure_firewall
    test_apache

    color ""
    color green "===================== Apache 安装程序已完成 ====================="
    color ""
}


################### Start ####################
check_system_info
check_installed_info
get_version_info

# Show Install Information
clear
color blue "##########################################################"
color blue "# Auto Install Script for Apache 2.4                     #"
color blue "# Author: ttionya                                        #"
color blue "##########################################################"
color ""
color yellow "将安装 Apache ${LATEST_APACHE_VERSION}"
color ""
color yellow "依赖："
color yellow "    - APR ${LATEST_APR_VERSION}"
color yellow "    - APR-util ${LATEST_APR_UTIL_VERSION}"
color yellow "    - PCRE ${LATEST_PCRE_VERSION}"
color yellow "    - nghttp2 ${LATEST_NGHTTP2_VERSION}"
color yellow "    - OpenSSL ${LATEST_OPENSSL_VERSION}"
color ""
color yellow "CPU 核心数: ${CPU_NUM} 个"
color ""
color x "是否安装 ？ (y/n)"
read -p "(Default: n):" CHECK_INSTALL

# Check Install
if [[ $(echo ${CHECK_INSTALL:-n} | tr [a-z] [A-Z]) == Y ]]; then
    main
else
    color ""
    color blue "Apache 安装被取消..."
fi
################### End ####################

# Ver1.0.1
# - 添加 Proxy 和 SSL 支持
#
# Ver1.0.2
# - 修改 sock 文件位置，解决 systemctl 启动 php-fpm 出现无法找到 sock 文件的情况
#
# Ver1.1.0
# - 修改 PCRE 下载源到其 FTP，以解决 SF 更新滞后的问题
# - 更新 PCRE 和 nghttp2 版本
#
# Ver2.0.0
# - 优化变量命名方式
# - 拆分流程到函数中
# - 更新 PCRE 和 nghttp2 版本
# - 添加 OpenSSL 1.1.1 编译安装以支持 TLS 1.3
# - 用询问替代强制重新安装依赖
# - 优化脚本
#
# Ver2.0.1
# - 修改配置文件，以适配 PHP 测试
#
# Ver2.0.2
# - 添加 mod_proxy_http2 模块支持
