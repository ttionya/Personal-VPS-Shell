#!/usr/bin/env bash
#
# Oh My Zsh
#
# Version: 3.0.3
# Author: ttionya
#
# Usage:
#     bash pvs_omz.sh [ install | configure | update | uninstall ] [ [options] ]


#################### Custom Setting ####################
DEFAULT_COMMAND="INSTALL"
# 时区（留空使用服务器时区）
TIMEZONE=""
# 中国镜像
CHINA_MIRROR="FALSE"
# Zsh Theme (https://github.com/ohmyzsh/ohmyzsh/wiki/Themes)
OMZ_THEME="ys"
# Zsh Plugins (https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins)
OMZ_PLUGINS="cp docker docker-compose encode64 extract git history man node npm pip pm2 python redis-cli rsync screen sudo systemd ufw yarn z"


#################### Variables ####################
OMZ_BIN="${HOME}/.oh-my-zsh/oh-my-zsh.sh"
OMZ_CONFIG_FILE="${HOME}/.zshrc"


#################### Function ####################
########################################
# Check that Oh My Zsh is installed.
# Arguments:
#     None
########################################
function check_installed() {
    if [[ -f "${OMZ_BIN}" ]]; then
        return 1
    else
        return 0
    fi
}

########################################
# Check that Git is installed.
# Arguments:
#     None
########################################
function check_git_installed() {
    if ! command -v git > /dev/null 2>&1; then
        error "未找到已安装的 Git"
        exit 1
    fi
}

########################################
# Check that Zsh is installed.
# Arguments:
#     None
########################################
function check_zsh_installed() {
    if command -v zsh > /dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

########################################
# Check package manager.
# Arguments:
#     None
########################################
function check_package_manager() {
    PACKAGE_MANAGER=""

    command -v yum > /dev/null 2>&1 && PACKAGE_MANAGER="YUM"
    command -v apt > /dev/null 2>&1 && PACKAGE_MANAGER="APT"

    if [[ -z "${PACKAGE_MANAGER}" ]]; then
        error "该脚本仅支持 yum, apt 包管理器"
        exit 1
    fi
}

########################################
# Install Zsh.
# Arguments:
#     None
########################################
function install_zsh() {
    color blue "========================================"
    info "Zsh 安装中..."

    case "${PACKAGE_MANAGER}" in
        YUM)
            yum -y install zsh
            if [[ "$?" != "0" ]]; then
                error "Zsh 安装失败"
                exit 1
            fi
            ;;
        APT)
            apt-get -y update
            apt-get -y install zsh
            if [[ "$?" != "0" ]]; then
                error "Zsh 安装失败"
                exit 1
            fi
            ;;
    esac

    success "Zsh 安装成功"
}

# install main
function install_main() {
    color blue "========================================"
    info "安装 Oh My Zsh 中..."

    # install
    wget -c -t3 -T60 -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash
    if [[ "$?" != "0" ]]; then
        error "安装 Oh My Zsh 失败"
        exit 1
    fi

    success "安装 Oh My Zsh 成功"
}

# configure main
function configure_main() {
    color blue "========================================"
    info "配置 Oh My Zsh 中..."

    local LINE_NUMBER

    if [[ -f "${OMZ_CONFIG_FILE}" ]]; then
        # git
        git config --global oh-my-zsh.hide-status 1

        # theme
        sed -i 's@^ZSH_THEME=.*@ZSH_THEME="'"${OMZ_THEME}"'"@' "${OMZ_CONFIG_FILE}"

        # plugins
        sed -i 's@^plugins=@# plugins=@' "${OMZ_CONFIG_FILE}"
        LINE_NUMBER="$(sed -n '/# plugins=/=' "${OMZ_CONFIG_FILE}" | tail -n 1)"
        sed -i "${LINE_NUMBER}"'a\plugins=('"${OMZ_PLUGINS}"')' "${OMZ_CONFIG_FILE}"

        # language
        sed -i 's@^export LANG=@# export LANG=@' "${OMZ_CONFIG_FILE}"
        LINE_NUMBER="$(sed -n '/# export LANG=/=' "${OMZ_CONFIG_FILE}" | tail -n 1)"
        sed -i "${LINE_NUMBER}"'a\export LANG=en_US.UTF-8' "${OMZ_CONFIG_FILE}"

        # Fix numeric keypad
        # https://github.com/robbyrussell/oh-my-zsh/issues/2654
        if [[ "$(grep -c 'Fix numeric keypad' "${OMZ_CONFIG_FILE}")" == "0" ]]; then
            cat >> "${OMZ_CONFIG_FILE}" << EOF

# Fix numeric keypad
bindkey -s "^[Op" "0"
bindkey -s "^[On" "."
bindkey -s "^[OM" "^M"
bindkey -s "^[Oq" "1"
bindkey -s "^[Or" "2"
bindkey -s "^[Os" "3"
bindkey -s "^[Ot" "4"
bindkey -s "^[Ou" "5"
bindkey -s "^[Ov" "6"
bindkey -s "^[Ow" "7"
bindkey -s "^[Ox" "8"
bindkey -s "^[Oy" "9"
bindkey -s "^[Ol" "+"
bindkey -s "^[Om" "-"
bindkey -s "^[Oj" "*"
bindkey -s "^[Oo" "/"
EOF
        fi

        # Fix Home / End key
        # https://github.com/robbyrussell/oh-my-zsh/issues/3061
        if [[ "$(grep -c '# Fix Home / End key' "${OMZ_CONFIG_FILE}")" == "0" ]]; then
            cat >> "${OMZ_CONFIG_FILE}" << EOF

# Fix Home / End key
bindkey "\033[1~" beginning-of-line
bindkey "\033[4~" end-of-line
EOF
        fi
    fi

    # Change default shell
    chsh -s "$(which zsh)"

    success "配置 Oh My Zsh 完成"
}

# install
function install() {
    check_installed
    if [[ "$?" == "1" ]]; then
        color yellow "发现已安装的 Oh My Zsh，你可以："
        color yellow "1. 使用 omz update 升级版本"
        color yellow "2. 使用 uninstall_oh_my_zsh 卸载后重新使用 install 安装"
        exit 1
    fi

    check_git_installed

    local READ_OMZ_INSTALL

    clear
    color blue "##########################################################"
    color blue "# Auto Install Script for Oh My Zsh"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将为 $(whoami) 安装 Oh My Zsh"
    color none ""
    color yellow "确认安装？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_OMZ_INSTALL="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_OMZ_INSTALL
    fi

    if [[ "${READ_OMZ_INSTALL^^}" == "Y" ]]; then
        if [[ "${EUID}" == "0" ]]; then
            install_zsh
        fi
        install_main
        configure_main
    else
        info "已取消 Oh My Zsh 安装"
    fi
}

# configure
function configure() {
    check_installed
    if [[ "$?" == "0" ]]; then
        color yellow "未发现已安装的 Oh My Zsh，你可以使用 install 安装"
        exit 1
    fi

    check_git_installed

    local READ_OMZ_CONFIGURE

    clear
    color blue "##########################################################"
    color blue "# Auto Configure Script for Oh My Zsh"
    color blue "# Author: ttionya"
    color blue "##########################################################"
    color none ""
    color yellow "将为 $(whoami) 配置 Oh My Zsh"
    color none ""
    color yellow "确认配置？ (y/N)"
    if [[ "${ASSUME_YES}" == "TRUE" ]]; then
        READ_OMZ_CONFIGURE="y"
        color none "(Default: n): y"
    else
        read -p "(Default: n): " READ_OMZ_CONFIGURE
    fi

    if [[ "${READ_OMZ_CONFIGURE^^}" == "Y" ]]; then
        configure_main
    else
        info "已取消 Oh My Zsh 配置"
    fi
}

# update
function update() {
    check_installed
    if [[ "$?" == "0" ]]; then
        color yellow "未发现已安装的 Oh My Zsh，你可以使用 install 安装"
        exit 1
    fi

    color yellow "请使用 omz update 升级 Oh My Zsh"
}

# uninstall
function uninstall() {
    check_installed
    if [[ "$?" == "0" ]]; then
        color yellow "未发现已安装的 Oh My Zsh"
        exit 1
    fi

    color yellow "请使用 uninstall_oh_my_zsh 卸载 Oh My Zsh"
}

# main
function main() {
    check_zsh_installed
    if [[ "$?" == "0" ]]; then
        if [[ "${EUID}" != "0" ]]; then
            error "该脚本必须以 root 权限运行安装 Zsh"
            exit 1
        fi

        check_package_manager
    fi
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


# v1.0.1
#
# - 修复小键盘可能失效的问题
#
# v1.0.2
#
# - 修复 Home 和 End 键不正常工作的问题
#
# v1.0.3
#
# - 移除多余的 source 命令
# - 使用丑陋的方法处理 plugins 问题
#
# v1.0.4
#
# - 添加 Docker Compose 插件支持
#
# v1.1.0
#
# - 添加更多颜色支持
# - 优化脚本
# - 修改安装逻辑
#
# v2.0.0
#
# - 重构脚本
#
# v2.1.0
#
# - 修改文案
# - 优化依赖
#
# v2.1.1
#
# - 修改插件
# - 优化脚本
#
# v3.0.0
#
# - 修改为 Debian 版
#
# v3.0.1
#
# - 使用 apt-get 替代 apt
#
# v3.0.2
#
# - 修改启用插件
#
# v3.0.3
#
# - 修改默认 shell
