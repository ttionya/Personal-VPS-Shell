#!/usr/bin/env bash
#
# Git
#
# Version: 2.2.0
# Author: ttionya
#
# Usage:
#     bash pvs_git.sh [ install | update | uninstall ] [ [options] ]


#################### Custom Setting ####################
DEFAULT_COMMAND="INSTALL"
# 时区（留空使用服务器时区）
TIMEZONE=""
# 中国镜像
CHINA_MIRROR="FALSE"
# Git 版本号
GIT_VERSION="2.37.3"
# Git 安装路径
INSTALL_GIT_PATH="/usr/local/git"


#################### Variables ####################
SRC_DIR="/usr/local/src"
GIT_SRC_FILE="${SRC_DIR}/git-${GIT_VERSION}.tar.gz"
GIT_SRC_DIR="${SRC_DIR}/git-${GIT_VERSION}"
GIT_BIN="${INSTALL_GIT_PATH}/bin/git"
GIT_BAK="${INSTALL_GIT_PATH}.bak"


#################### Function ####################
########################################
# Check that Git is installed.
# Arguments:
#     None
########################################
function check_installed() {
    if command -v "${GIT_BIN}" > /dev/null 2>&1; then
        GIT_VERSION_INSTALLED="$("${GIT_BIN}" --version | grep -oE "[0-9.]+")"
        return 1
    else
        return 0
    fi
}

########################################
# Install dependencies.
# Arguments:
#     None
########################################
function install_dependencies() {
    color blue "========================================"
    info "依赖安装中..."

    yum -y install autoconf curl-devel diffutils expat-devel gcc gcc-c++ gettext make wget zlib-devel
    if [[ $? -ne 0 ]]; then
        error "依赖安装失败"
        exit 1
    fi

    success "依赖安装成功"
}

# install main
function install_main() {
    color blue "========================================"
    info "编译安装 Git 中..."

    mkdir -p "${SRC_DIR}"
    cd "${SRC_DIR}"

    # download
    if [[ ! -s "${GIT_SRC_FILE}" ]]; then
        wget -c -t3 -T60 "https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz" -O "${GIT_SRC_FILE}"
        if [[ $? -ne 0 ]]; then
            error "Git 下载失败"
            rm -rf "${GIT_SRC_FILE}"
            exit 1
        fi
    fi

    # extract
    rm -rf "${GIT_SRC_DIR}"
    tar -zxvf "${GIT_SRC_FILE}"

    # configure
    cd "${GIT_SRC_DIR}"

	local CFLAGS=""
	if [[ "${SYSTEM_MAJOR_VERSION}" -eq 7 ]]; then
		# https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5948/diffs
		CFLAGS="-std=gnu99"
	fi

    make configure
    ./configure --prefix="${INSTALL_GIT_PATH}" NO_TCLTK=YesPlease CFLAGS="${CFLAGS}"
    if [[ $? -ne 0 ]]; then
        error "Git 配置失败"
        exit 1
    fi
    make all -j "${CPU_NUMBER}"
    if [[ $? -ne 0 ]]; then
        error "Git 编译失败"
        make clean
        exit 1
    fi

    if [[ "${COMMAND}" == "INSTALL" ]]; then # INSTALL
        # install
        make install
        if [[ $? -ne 0 ]]; then
            error "Git 安装失败"
            rm -rf "${INSTALL_GIT_PATH}"
            exit 1
        fi
    elif [[ "${COMMAND}" == "UPDATE" ]]; then # UPDATE
        # check backup
        rm -rf "${GIT_BAK}"
        mv "${INSTALL_GIT_PATH}" "${GIT_BAK}"

        # install
        make install
        if [[ $? -ne 0 ]]; then
            error "Git 安装失败"
            rm -rf "${INSTALL_GIT_PATH}"
            mv "${GIT_BAK}" "${INSTALL_GIT_PATH}"
            exit 1
        fi
    fi

    # configure
    ln -sf "${GIT_BIN}" /usr/local/bin/

    # clean
    cd "${SRC_DIR}"
    rm -rf "${GIT_SRC_DIR}"

    success "编译安装 Git 成功"
}

# uninstall main
function uninstall_main() {
    color blue "========================================"
    info "卸载 Git 中..."

    rm -rf "${INSTALL_GIT_PATH}" /usr/local/bin/git

    success "卸载 Git 完成"
}

# install
function install() {
    check_installed
    if [[ $? -eq 1 ]]; then
        color yellow "发现已安装的 Git，你可以："
        color yellow "1. 使用 update 升级版本"
        color yellow "2. 使用 uninstall 卸载后重新使用 install 安装"
        exit 1
    fi

    local READ_GIT_INSTALL

    clear
    color blue "##########################################################"
    color blue "# Auto Install Script for Git"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将安装 Git ${GIT_VERSION}"
    color none ""
    color yellow "确认安装？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_GIT_INSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_GIT_INSTALL
    fi

    if [[ "${READ_GIT_INSTALL^^}" == "Y" ]]; then
        install_dependencies
        install_main
    else
        info "已取消 Git ${GIT_VERSION} 安装"
    fi
}

# update
function update() {
    check_installed
    if [[ $? -eq 0 ]]; then
        color yellow "未发现已安装的 Git，你可以使用 install 安装"
        exit 1
    fi

    local READ_GIT_UPDATE

    clear
    color blue "##########################################################"
    color blue "# Auto Update Script for Git"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "Git ${GIT_VERSION_INSTALLED} -> Git ${GIT_VERSION}"
    color none ""
    color yellow "确认升级？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_GIT_UPDATE="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_GIT_UPDATE
    fi

    if [[ "${READ_GIT_UPDATE^^}" == "Y" ]]; then
        install_dependencies
        install_main
    else
        info "已取消 Git ${GIT_VERSION} 升级"
    fi
}

# uninstall
function uninstall() {
    check_installed
    if [[ $? -eq 0 ]]; then
        color yellow "未发现已安装的 Git"
        exit 1
    fi

    local READ_GIT_UNINSTALL

    clear
    color blue "##########################################################"
    color blue "# Auto Uninstall Script for Git"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将卸载 Git ${GIT_VERSION_INSTALLED}"
    color none ""
    color yellow "确认卸载？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_GIT_UNINSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_GIT_UNINSTALL
    fi

    if [[ "${READ_GIT_UNINSTALL^^}" == "Y" ]]; then
        uninstall_main
    else
        info "已取消 Git ${GIT_VERSION_INSTALLED} 卸载"
    fi
}

# main
function main() {
    check_root
    check_os_version 7 8 9

    get_cpu_number
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


# v1.0.1
#
# - 添加遗漏的依赖项
#
# v1.1.0
#
# - 更新 Git 安装版本
# - 美化安装界面
# - 优化脚本
#
# v2.0.0
#
# - 重构脚本
#
# v2.1.0
#
# - 优化依赖
#
# v2.1.1
#
# - 优化依赖，移除非必要依赖
#
# v2.1.2
#
# - 使用绝对路径
#
# v2.2.0
#
# - 更新 Git 安装版本
# - 修复 CentOS 7 安装报错问题
# - 支持 CentOS 9
