#!/usr/bin/env bash
#
# MySQL 8.4 Community repository
#
# Version: 1.0.0
# Author: ttionya
#
# Usage:
#     bash repo_mysql84.sh [ install | uninstall ] [ [options] | --install-only ]
#
# https://dev.mysql.com/doc/mysql-apt-repo-quick-guide/en/
# https://dev.mysql.com/doc/refman/8.4/en/checking-gpg-signature.html


#################### Custom Setting ####################
DEFAULT_COMMAND="INSTALL"
# 时区（留空使用服务器时区）
TIMEZONE=""
# 中国镜像
CHINA_MIRROR="FALSE"


#################### Variables ####################
REPO_CONFIG_FILE="/etc/apt/sources.list.d/mysql.list"
REPO_GPG_FILE="/etc/apt/keyrings/mysql.gpg"
TMP_GPG_FILE="/tmp/mysql.gpg"


#################### Function ####################
########################################
# Check that MySQL repository is installed.
# Arguments:
#     None
########################################
function check_installed() {
    if [[ -f "${REPO_CONFIG_FILE}" ]]; then
        REPO_INSTALLED="TRUE"
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

    apt-get -y update
    apt-get -y install ca-certificates curl gnupg
    if [[ "$?" != "0" ]]; then
        error "依赖安装失败"
        exit 1
    fi

    success "依赖安装成功"
}

# install main
function install_main() {
    color blue "========================================"
    info "安装 MySQL repository 中..."

    mkdir -p "$(dirname "${REPO_GPG_FILE}")"
    rm -rf "${REPO_GPG_FILE}"

    # import GPG
    cat > "${TMP_GPG_FILE}" << EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: SKS 1.1.6
Comment: Hostname: pgp.mit.edu

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
cAZUlaj3id3TxquAlud4lWDz
=h5nH
-----END PGP PUBLIC KEY BLOCK-----
EOF
    cat "${TMP_GPG_FILE}" | gpg --dearmor -o "${REPO_GPG_FILE}"
    if [[ "$?" != "0" ]]; then
        rm -rf "${TMP_GPG_FILE}"
        error "安装 MySQL repository 失败"
        exit 1
    fi
    rm -rf "${TMP_GPG_FILE}"
    chmod a+r "${REPO_GPG_FILE}"

    # configure
    echo "deb [arch=$(dpkg --print-architecture) signed-by=${REPO_GPG_FILE}] https://repo.mysql.com/apt/debian/ $(. /etc/os-release && echo "${VERSION_CODENAME}") mysql-8.4-lts" > "${REPO_CONFIG_FILE}"

    success "安装 MySQL repository 成功"
}

# uninstall main
function uninstall_main() {
    color blue "========================================"
    info "卸载 MySQL repository 中..."

    rm -rf "${REPO_CONFIG_FILE}" "${REPO_GPG_FILE}"

    apt-get -y update

    success "卸载 MySQL repository 完成"
}

# install
function install() {
    check_installed

    local READ_REPO_INSTALL
    local INSTALL_TEXT="安装"

    if [[ "${REPO_INSTALLED}" == "TRUE" ]]; then
        # 只允许安装
        if [[ "${OPTION_INSTALL_ONLY}" == "TRUE" ]]; then
            warn "检测到已安装 MySQL repository，跳过"
            exit 0
        fi

        INSTALL_TEXT="重新安装"
    fi

    clear
    color blue "##########################################################"
    color blue "# Auto Install Script for MySQL 8.4 Community Repository"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将${INSTALL_TEXT} MySQL repository"
    color none ""
    color yellow "确认${INSTALL_TEXT}？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_REPO_INSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_REPO_INSTALL
    fi

    if [[ "${READ_REPO_INSTALL^^}" == "Y" ]]; then
        install_dependencies
        if [[ "${REPO_INSTALLED}" == "TRUE" ]]; then
            uninstall_main
        fi
        install_main
    else
        info "已取消 MySQL repository ${INSTALL_TEXT}"
    fi
}

# uninstall
function uninstall() {
    check_installed
    if [[ "$?" == "0" ]]; then
        color yellow "未发现已安装的 MySQL repository"
        exit 1
    fi

    local READ_REPO_UNINSTALL

    clear
    color blue "##########################################################"
    color blue "# Auto Uninstall Script for MySQL 8.4 Community Repository"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将卸载 MySQL repository"
    color none ""
    color yellow "确认卸载？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_REPO_UNINSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_REPO_UNINSTALL
    fi

    if [[ "${READ_REPO_UNINSTALL^^}" == "Y" ]]; then
        uninstall_main
    else
        info "已取消 MySQL repository 卸载"
    fi
}

# main
function main() {
    check_root
    check_os_version 11 12
}

# dep
function dep() {
    local FUNCTION_URL="https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/debian/functions.sh"

    for ARGS_ITEM in $*;
    do
        if [[ "${ARGS_ITEM}" == "--china" ]]; then
            CHINA_MIRROR="TRUE"
            FUNCTION_URL="https://gitee.com/ttionya/Personal-VPS-Shell/raw/debian/functions.sh"
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
