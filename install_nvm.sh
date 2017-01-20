#!/bin/bash

# Version: 1.0.0
# Author: ttionya


################### Custom Setting ####################
# 执行本脚本的用户，用 `whoami` 查看
Current_User="root"
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# 以下变量涉及 rm -rf，乱来你就死定了，路径最后不要加上斜杠 /
# NodeJS 安装目录（绝对路径），使用 yum 安装或未曾安装过留空
Installed_NodeJS_Path=""
# NPM 安装缓存目录（绝对路径），默认为 `~/.npm`，多个用空格隔开，不删除则留空
NPM_Cache_Path="~/.npm ~/.npminstall_tarball ~/.pki" # 普通用户，可用 ~
# NPM 全局安装路径，默认为 `/usr/lib/node_modules` 或 `/usr/local/lib/node_modules`，可用空格隔开，不删除则留空
NPM_Global_Path="/usr/lib/node_modules /usr/local/lib/node_modules"
# NPM 可执行文件路径，默认为 `/usr/bin` 或 `/usr/local/bin`，可用空格隔开，不删除则留空，会删除全部失效软链接
NPM_Bin_Path="/usr/bin /usr/local/bin"


################### Check Info Start ####################
# Check root User
if [ $EUID != 0 ]; then
   echo "错误：该脚本必须以 root 身份运行"
   echo "可以在 Custom Setting 中修改指定用户"
   exit 1
fi

# Check Current User
Current_User_Info=`cat /etc/passwd | grep -oE "^$Current_User:(.*)"`
if [ -z $Current_User_Info ]; then
    echo "执行本脚本的用户不存在"
    exit 1
# else
#    Current_User_Shell=`echo $Current_User_Info | cut -d: -f7`
#    if [ $Current_User_Shell == "/sbin/nologin" ]; then
#        echo "执行脚本的用户"
fi

# Check CentOS Version
# CentOS 6.X Only
if [ -s /etc/redhat-release ]; then
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/redhat-release`
else
    CentOS_Ver=`grep -oE  "[0-9.]+" /etc/issue`
fi
CentOS_Ver=${CentOS_Ver%%.*}
if [ $CentOS_Ver != 6 ]; then
    echo "错误：该脚本仅支持 CentOS 6.X 版本"
    echo "因为没有在其他版本上做测试"
    exit 1
fi

echo "正在获取 NVM 版本信息..."

Latest_NVM_Ver=`curl -s https://github.com/creationix/nvm/tags | grep tag-name | head -n 1 | sed 's/\s*<[^>]*>\(.\+\)<[^>]*>/\1/'`
################### Check Info End ####################


# Main Function
function main() {
    echo ""
    echo "===================== NVM 安装程序 启动 ===================="

    # Remove Exist NodeJS
    if [ -z "$Installed_NodeJS_Path" ]; then
        yum remove -y nodejs
    else
        rm -rf $Installed_NodeJS_Path
    fi

    # Remove NPM Cache Directory
    if [ -n "$NPM_Cache_Path" ]; then
        su - $Current_User -c "rm -rf ${NPM_Cache_Path//\"/\\\"}"
    fi

    # Remove NPM Global Directory
    if [ -n "$NPM_Global_Path" ]; then
        rm -rf $NPM_Global_Path
    fi

    # Remove NPM Bin Directory
    if [ -n "$NPM_Bin_Path" ]; then
        find -L $NPM_Bin_Path -type l -delete
    fi

    # Switch User
    su - $Current_User <<HERE

        # Install Latest NVM Version
        echo ""
        echo "开始下载 NVM..."
        echo ""
        wget -c -t3 -T60 -qO- "https://raw.githubusercontent.com/creationix/nvm/$Latest_NVM_Ver/install.sh" | bash
        if [ $? != 0 ]; then
            echo "NVM 安装失败"
            exit 1
        fi
        echo "安装成功，正在进行配置..."

        # Switch NVM Source to Taobao
        if [ -f ~/.bashrc ]; then
            Find_NVM_Mirror=`cat ~/.bashrc | grep -oE "^(# )?export NVM_NODEJS_ORG_MIRROR(.*)$"`
            if [ -n "$Find_NVM_Mirror" ]; then
                sed -i 's/^export NVM_NODEJS_ORG_MIRROR\(.*\)/# export NVM_NODEJS_ORG_MIRROR\1/' ~/.bashrc
            fi
        fi
        echo "export NVM_NODEJS_ORG_MIRROR=https://npm.taobao.org/mirrors/node" >> ~/.bashrc
        echo ""
        echo "已将淘宝源作为 NVM 源"

        # Switch NPM Source to Taobao
        if [ -f ~/.npmrc ]; then
            Find_NPM_Registry=`cat ~/.npmrc | grep -oE "^registry"`
            if [ -n "$Find_NPM_Registry" ]; then
                sed -i 's/^registry\(.*\)/# registry\1/' ~/.npmrc
            fi
        fi
        echo "registry=https://registry.npm.taobao.org/" >> ~/.npmrc
        echo ""
        echo "已将淘宝源作为 NPM 源"

        # Source
        if [ -f ~/.profile ]; then
            source ~/.profile
        fi
        if [ -f ~/.bashrc ]; then
            source ~/.bashrc
        fi
        if [ -f ~/.bash_profile ]; then
            source ~/.bash_profile
        fi
        if [ -f ~/.zshrc ]; then
            source ~/.zshrc
        fi

        # Install Latest NodeJS
        nvm install node
        npm i -g cnpm

        echo "===================== NVM 安装配置完成 ===================="
    exit
HERE
}

# Show Install Information
clear
echo "##########################################################"
echo "# Auto Install Script for NVM                            #"
echo "# System Required:  CentOS / RedHat 6.X                  #"
echo "# Author: ttionya                                        #"
echo "##########################################################"
echo ""
echo "将安装 NVM $Latest_NVM_Ver"
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
    echo "NVM 安装被取消，未作任何更改..."
    echo ""
fi