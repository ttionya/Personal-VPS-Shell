#!/bin/bash

# Version: 1.1.0
# Author: ttionya


################### Custom Setting ####################
# Zsh Theme (https://github.com/robbyrussell/oh-my-zsh/wiki/Themes)
Zsh_Theme="ys"
# Zsh Plugins 用空格隔开 (https://github.com/robbyrussell/oh-my-zsh/wiki/Plugins)
Zsh_Plugins="git composer docker docker-compose encode64 extract grunt gulp history man ng node npm npx nvm pip python redis-cli screen sudo yum yarn z"

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

################### Check Info Start ####################
# Check Zsh
if ! command -v zsh >/dev/null 2>&1; then
    if [[ ${EUID} != 0 ]]; then
        color red "错误：需要 root 身份安装 Zsh"
        exit 1
    fi
fi

# Check Package Manager
PM=""
command -v yum >/dev/null 2>&1 && PM="yum"
command -v apt-get >/dev/null 2>&1 && PM="apt"
if [[ -z ${PM} ]]; then
    color red "错误：该脚本仅支持 yum, apt 包管理器"
    exit 1
fi
################### Check Info End ####################


# Main Function
function main() {
    color ""
    color yellow "===================== Oh My Zsh 安装程序 启动 ===================="

    # Check Git
    if ! command -v git >/dev/null 2>&1; then
        color red "错误：未找到 Git 命令"
        exit 1
    fi

    # Install Oh My Zsh
    wget -c -t3 -T60 -qO- "https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh" | sh
    if [[ $? != 0 ]]; then
        echo -e "\033[31m错误：Oh My Zsh 安装失败\033[0m"
        exit 1
    fi

    color ""
    color green "安装成功，正在进行配置..."

    # Setting ~/.zshrc
    if [[ -f ~/.zshrc ]]; then
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="'${Zsh_Theme}'"/' ~/.zshrc

        sed -i 's/^plugins=\(.*\)/# plugins=\1/' ~/.zshrc
        sed -i 's/^source\(.*\)/# source\1/' ~/.zshrc
        cat >> ~/.zshrc << EOF

plugins=(${Zsh_Plugins})

source \$ZSH/oh-my-zsh.sh
EOF

        # Fix numeric keypad
        # https://github.com/robbyrussell/oh-my-zsh/issues/2654
        cat >> ~/.zshrc << EOF

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

        # Fix Home / End key
        # https://github.com/robbyrussell/oh-my-zsh/issues/3061
        cat >> ~/.zshrc << EOF

# Fix Home / End key
bindkey "\033[1~" beginning-of-line
bindkey "\033[4~" end-of-line
EOF
    fi

    color ""
    color green "===================== Oh My Zsh 安装配置完成 ===================="
}

# Install Zsh
function install_zsh() {
    case ${PM} in
    yum)
        yum install -y zsh
        ;;
    apt)
        apt-get install -y zsh
        ;;
    esac
}

# root User Install Zsh
if [[ ${EUID} == 0 ]]; then
    install_zsh
fi

# Show Install Information
clear
color blue "##########################################################"
color blue "# Auto Install Script for Oh My Zsh                      #"
color blue "# Author: ttionya                                        #"
color blue "##########################################################"
color ""
color yellow "将为 $(whoami) 用户安装 Oh My Zsh"
color ""
color x "是否安装？ (y/n)"
read -p "(Default: n):" Check_Install
if [[ -z ${Check_Install} ]]; then
    Check_Install="n"
fi

# Check Install
if [[ ${Check_Install} == y || ${Check_Install} == Y ]]; then
    main
else
    color ""
    color blue "Oh My Zsh 安装被取消，未作任何更改..."
    color ""
fi


# 删除 oh-my-zsh
# uninstall_oh_my_zsh

# Ver1.0.1
# - 修复小键盘可能失效的问题
#
# Ver1.0.2
# - 修复 Home 和 End 键不正常工作的问题
#
# Ver1.0.3
# - 移除多余的 source 命令
# - 使用丑陋的方法处理 plugins 问题
#
# Ver1.0.4
# - 添加 Docker Compose 插件支持
#
# Ver1.1.0
# - 添加更多颜色支持
# - 优化脚本
# - 修改安装逻辑
