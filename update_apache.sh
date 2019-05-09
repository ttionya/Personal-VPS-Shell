#!/usr/bin/env bash

# Version: 2.0.1
# Author: ttionya


################### Customer Setting ####################
# 下载地址
DOWNLOAD_PATH="/usr/local/src"
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
    if [[ ! -d ${INSTALL_APACHE_PATH} ]]; then
        color red "错误：未在指定位置找到 Apache 目录"
        exit 1
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
    INSTALLED_APACHE_VERSION="$(${INSTALL_APACHE_PATH}/bin/httpd -v | grep Apache | awk '{print $3}' | awk -F '/' '{print $2}')"

    # Check CPU Number
    CPU_NUM=$(grep -c 'processor' /proc/cpuinfo)
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
    ls -1 | grep -P 'pcre-[0-9.]+' | grep -v "${LATEST_PCRE_VERSION}" | xargs -I {} rm -rf {}

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
    ls -1 | grep -P 'nghttp2-[0-9.]+' | grep -v "${LATEST_NGHTTP2_VERSION}" | xargs -I {} rm -rf {}

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
    ls -1 | grep -P 'openssl-[0-9.]+[a-z]?' | grep -v "${LATEST_OPENSSL_VERSION}" | xargs -I {} rm -rf {}

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

# Update Apache
function update_apache() {
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

    # Backup
    systemctl stop httpd.service
    if [[ -d ${INSTALL_APACHE_PATH} ]]; then
        rm -rf ${INSTALL_APACHE_PATH}.bak
        mv ${INSTALL_APACHE_PATH} ${INSTALL_APACHE_PATH}.bak
    fi

    # Install
    make install
    if [[ $? != 0 ]]; then
        rm -rf ${INSTALL_APACHE_PATH}
        mv ${INSTALL_APACHE_PATH}.bak ${INSTALL_APACHE_PATH}
        systemctl restart httpd.service
        color ""
        color red "错误：Apache 安装失败"
        exit 1
    fi

    # Copy Config Files
    mv ${INSTALL_APACHE_PATH}/conf ${INSTALL_APACHE_PATH}/conf.new
    cp -rf ${INSTALL_APACHE_PATH}.bak/conf ${INSTALL_APACHE_PATH}/
    cp -rf ${INSTALL_APACHE_PATH}.bak/logs ${INSTALL_APACHE_PATH}/
    cp -rfu ${INSTALL_APACHE_PATH}.bak/modules ${INSTALL_APACHE_PATH}/

    # Start Apache
    systemctl restart httpd.service

    # Clean Up
    cd ${DOWNLOAD_PATH}
    rm -rf ${DIR_SOURCE_APACHE}
    ls -1 | grep -P 'apr-[0-9.]+' | grep -v "${LATEST_APR_VERSION}" | xargs -I {} rm -rf {}
    ls -1 | grep -P 'apr-util-[0-9.]+' | grep -v "${LATEST_APR_UTIL_VERSION}" | xargs -I {} rm -rf {}
    ls -1 | grep -P 'httpd-[0-9.]+' | grep -v "${LATEST_APACHE_VERSION}" | xargs -I {} rm -rf {}

    # Result
    color ""
    color green "===================== Apache 升级完成 ====================="
    color ""
}

# Main
function main() {
    color ""
    color blue "===================== Apache 升级程序启动 ====================="

    install_dependencies

    check_pcre
    check_nghttp2
    check_openssl
    update_apache

    color ""
    color green "===================== Apache 升级程序已完成 ====================="
    color ""
}


################### Start ####################
check_system_info
check_installed_info
get_version_info

# Show Update Information
clear
color blue "##########################################################"
color blue "# Auto Update Script for Apache 2.4                      #"
color blue "# Author: ttionya                                        #"
color blue "##########################################################"
color ""
color yellow "将安装 Apache ${LATEST_APACHE_VERSION}"
color yellow "已安装 Apache ${INSTALLED_APACHE_VERSION}"
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
color x "是否更新 ？ (y/n)"
read -p "(Default: n):" CHECK_UPDATE

# Check Update
if [[ $(echo ${CHECK_UPDATE:-n} | tr [a-z] [A-Z]) == Y ]]; then
    main
else
    color ""
    color blue "Apache 升级被取消..."
fi
################### End ####################

# Ver1.0.1
# - 修复某些地区的 apr.apache.org/download.cgi 改版引起的问题
#
# Ver2.0.0
# - 优化变量命名方式
# - 拆分流程到函数中
# - 更新 PCRE 和 nghttp2 版本
# - 更新 OpenSSL 1.1.1 编译安装以支持 TLS 1.3
# - 用询问替代强制重新安装依赖
# - 优化脚本
#
# Ver2.0.1
# - 添加 mod_proxy_http2 模块支持
