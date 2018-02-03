#!/bin/bash

# Version: 1.0.3
# Author: ttionya


################### Custom Setting ####################
# 执行本脚本的用户，用 `whoami` 查看
Current_User="root"
# Zsh Theme (https://wiki.github.com/robbyrussell/oh-my-zsh/themes)
Zsh_Theme="ys"
# Zsh Plugins 用空格隔开 (https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins)
Zsh_Plugins="git composer docker encode64 extract grunt gulp history ng node npm nvm python redis-cli screen sudo yum yarn z"

################### Check Info Start ####################
# Check root User
if [ $EUID != 0 ]; then
   echo "错误：该脚本必须以 root 身份运行"
   exit 1
fi

# Check Current User
Current_User_Info=`cat /etc/passwd | grep -oE "^$Current_User:(.*)"`
if [ -z $Current_User_Info ]; then
    echo "执行本脚本的用户不存在"
    exit 1
fi

# Check System
PM=""
which yum 1>/dev/null 2>/dev/null && PM="yum"
which apt-get 1>/dev/null 2>/dev/null && PM="apt"
which zypper 1>/dev/null 2>/dev/null && PM="zypper"
which pacman 1>/dev/null 2>/dev/null && PM="pacman"
if [ -z "$PM" ]; then
    echo "错误：该脚本仅支持 yum, apt, zypper, pacman 包管理器"
    exit 1
fi
################### Check Info End ####################


# Main Function
function main() {
    echo ""
    echo "===================== Oh My Zsh 安装程序 启动 ===================="

    # Install zsh
    case $PM in
    yum)
        yum install -y zsh
        ;;
    apt)
        apt-get install -y zsh
        ;;
    zypper)
        zypper install --no-confirm zsh
        ;;
    pacman)
        pacman -S zsh
        ;;
    esac

    # Switch User
    su - $Current_User << HERE

        # Install Oh My Zsh
        echo ""
        echo "开始下载 Oh My Zsh..."
        echo ""

        wget -c -t3 -T60 -qO- "https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh" | bash
        if [ $? != 0 ]; then
            echo "Oh My Zsh 安装失败"
            exit 1
        fi
        echo "安装成功，正在进行配置..."

        # Setting ~/.zshrc
        if [ -f ~/.zshrc ]; then
            sed -i 's/^ZSH_THEME=.*/ZSH_THEME="$Zsh_Theme"/' ~/.zshrc
            sed -i -e '/^plugins=[[:space:]]*(/,/^)/s/.*/plugins=($Zsh_Plugins)/p' ~/.zshrc
            mv ~/.zshrc ~/.zshrc.bak
            cat ~/.zshrc.bak | uniq > ~/.zshrc
            rm -f ~/.zshrc.bak # mmp

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

        echo "===================== Oh My Zsh 安装配置完成 ===================="
    exit
HERE
}

# Show Install Information
clear
echo "##########################################################"
echo "# Auto Install Script for Oh My Zsh                      #"
echo "# Author: ttionya                                        #"
echo "##########################################################"
echo ""
echo "将安装 Oh My Zsh"
echo ""
echo "是否安装？ (y/n)"
read -p "(Default: n):" Check_Install
if [ -z $Check_Install ]; then
    Check_Install="n"
fi

# Check Install
if [[ $Check_Install == y || $Check_Install == Y ]]; then
    main
else
    echo ""
    echo "Oh My Zsh 安装被取消，未作任何更改..."
    echo ""
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