#!/usr/bin/env bash
#
# ELRepo RPM repository
#
# Version: 3.1.0
# Author: ttionya
#
# Usage:
#     bash repo_elrepo.sh [ install | configure | update | uninstall ] [ [options] | --install-only ]


#################### Custom Setting ####################
DEFAULT_COMMAND="INSTALL"
# 时区（留空使用服务器时区）
TIMEZONE=""
# 中国镜像
CHINA_MIRROR="FALSE"


#################### Variables ####################
ELREPO_CONFIG_FILE="/etc/yum.repos.d/elrepo.repo"


#################### Function ####################
########################################
# Check that ELRepo RPM repository is installed.
# Arguments:
#     None
########################################
function check_installed() {
    rpm -q "elrepo-release" --quiet
    if [[ $? == 0 ]]; then
        ELREPO_INSTALLED="TRUE"
        return 1
    else
        return 0
    fi
}

########################################
# Configure repository china mirror.
# Arguments:
#     None
########################################
function configure_china_mirror() {
    if [[ "${CHINA_MIRROR}" == "TRUE" ]]; then
        sed -i 's@^baseurl=.*\.org/linux/\(.*\)@baseurl=https://mirrors.tuna.tsinghua.edu.cn/elrepo/\1@' "${ELREPO_CONFIG_FILE}"
        sed -i 's@^\(\thttp.*\)@#\1@' "${ELREPO_CONFIG_FILE}"
        sed -i 's@^mirrorlist=\(.*\)@#mirrorlist=\1@' "${ELREPO_CONFIG_FILE}"

        success "已设置清华大学源作为 ELRepo RPM repository 镜像源"
    fi
}

########################################
# Configure repository status.
# Arguments:
#     None
########################################
function configure_repository_status() {
    yum-config-manager --enable elrepo
    yum-config-manager --disable elrepo-kernel

    success "已启用 [elrepo] 并禁用 [elrepo-kernel]"
}

# install main
function install_main() {
    color blue "========================================"
    info "安装 ELRepo RPM repository 中..."

    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    yum -y install "https://www.elrepo.org/elrepo-release-${SYSTEM_MAJOR_VERSION}.el${SYSTEM_MAJOR_VERSION}.elrepo.noarch.rpm"
    if [[ $? != 0 ]]; then
        error "安装 ELRepo RPM repository 失败"
        exit 1
    fi

    success "安装 ELRepo RPM repository 成功"
}

# configure main
function configure_main() {
    color blue "========================================"
    info "配置 ELRepo RPM repository 中..."

    # install dependencies
    yum -y install yum-utils
    if [[ $? != 0 ]]; then
        error "依赖安装失败"
        exit 1
    fi

    configure_china_mirror
    configure_repository_status

    success "配置 ELRepo RPM repository 完成"
}

# update main
function update_main() {
    color blue "========================================"
    info "升级 ELRepo RPM repository 中..."

    yum -y update elrepo-release
    if [[ $? != 0 ]]; then
        error "升级 ELRepo RPM repository 失败"
        exit 1
    fi

    success "升级 ELRepo RPM repository 完成"
}

# uninstall main
function uninstall_main() {
    color blue "========================================"
    info "卸载 ELRepo RPM repository 中..."

    yum -y remove elrepo-release
    if [[ $? != 0 ]]; then
        error "卸载 ELRepo RPM repository 失败"
        exit 1
    fi

    yum clean all

    success "卸载 ELRepo RPM repository 完成"
}

# install
function install() {
    check_installed

    local READ_ELREPO_INSTALL
    local INSTALL_TEXT="安装"

    if [[ "${ELREPO_INSTALLED}" == "TRUE" ]]; then
        INSTALL_TEXT="重新安装"

        # 只允许安装
        if [[ "${OPTION_INSTALL_ONLY}" == "TRUE" ]]; then
            warn "检测到已安装 ELRepo RPM repository，跳过${INSTALL_TEXT}"
            exit 0
        fi
    fi

    clear
    color blue "##########################################################"
    color blue "# Auto Install Script for ELRepo RPM Repository"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将${INSTALL_TEXT} ELRepo RPM repository"
    color none ""
    color yellow "确认${INSTALL_TEXT}？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_ELREPO_INSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_ELREPO_INSTALL
    fi

    if [[ "${READ_ELREPO_INSTALL^^}" == "Y" ]]; then
        if [[ "${ELREPO_INSTALLED}" == "TRUE" ]]; then
            uninstall_main
        fi
        install_main
        configure_main
    else
        info "已取消 ELRepo RPM repository ${INSTALL_TEXT}"
    fi
}

# configure
function configure() {
    check_installed
    if [[ $? == 0 ]]; then
        color yellow "未发现已安装的 ELRepo RPM repository，你可以使用 install 安装"
        exit 1
    fi

    local READ_ELREPO_CONFIGURE

    clear
    color blue "##########################################################"
    color blue "# Auto Configure Script for ELRepo RPM Repository"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将配置 ELRepo RPM repository"
    color none ""
    color yellow "确认配置？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_ELREPO_CONFIGURE="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_ELREPO_CONFIGURE
    fi

    if [[ "${READ_ELREPO_CONFIGURE^^}" == "Y" ]]; then
        configure_main
    else
        info "已取消 ELRepo RPM repository 配置"
    fi
}

# update
function update() {
    check_installed
    if [[ $? == 0 ]]; then
        color yellow "未发现已安装的 ELRepo RPM repository，你可以使用 install 安装"
        exit 1
    fi

    update_main
}

# uninstall
function uninstall() {
    check_installed
    if [[ $? == 0 ]]; then
        color yellow "未发现已安装的 ELRepo RPM repository"
        exit 1
    fi

    local READ_ELREPO_UNINSTALL

    clear
    color blue "##########################################################"
    color blue "# Auto Uninstall Script for ELRepo RPM Repository"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将卸载 ELRepo RPM repository"
    color none ""
    color yellow "确认卸载？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_ELREPO_UNINSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_ELREPO_UNINSTALL
    fi

    if [[ "${READ_ELREPO_UNINSTALL^^}" == "Y" ]]; then
        uninstall_main
    else
        info "已取消 ELRepo RPM repository 卸载"
    fi
}

# main
function main() {
    check_root
    check_os_version 7 8
}

# dep
function dep() {
    local FUNCTION_URL="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/functions.sh"

    for ARGS_ITEM in $*;
    do
        if [[ "${ARGS_ITEM}" == "--china" ]]; then
            CHINA_MIRROR="TRUE"
            FUNCTION_URL="https://gitee.com/ttionya/Personal-VPS-Shell/raw/master/functions.sh"
        fi
    done

    source <(curl -sS -m 10 --retry 5 "${FUNCTION_URL}")
    if [[ "${PVS_INIT}" != "TRUE" ]]; then
        echo "依赖文件下载失败，请重试..."
        exit 1
    fi
}


#################### Start ####################
dep $*
#################### End ####################


# v2.0.0
#
# - 优化变量命名方式
# - 拆分流程到函数中
# - 用询问替代强制重新安装依赖
# - 优化脚本
# - 更新 ELRepo RPM Repository 版本
# - 新增脚本执行参数
#
# v2.1.0
#
# - 引用外部工具方法
# - 外部工具方法支持 github 和 gitee
# - 优化脚本
# - 启用 elrepo，禁用 elrepo-kernel
#
# v3.0.0
#
# - 重构脚本
#
# v3.0.1
#
# - 优化判断 RPM 包是否安装的逻辑
#
# v3.1.0
#
# - 支持 CentOS 8
# - 统一文案
# - 卸载 repository 后清除缓存
