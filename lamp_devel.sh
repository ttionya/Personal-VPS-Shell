#!/bin/bash

# Version: 1.0.1
# Author: ttionya

yum -y install \
autoconf automake \
bison bison-devel bzip2 bzip2-devel \
cpp curl curl-devel cmake \
freetype freetype-devel \
gcc gcc-c++ gd glibc glibc-devel gettext gettext-devel gmp gmp-devel \
lynx lua-devel libicu-devel libtool libjpeg-devel libpng-devel libxslt-devel libxml2-devel libwebp-devel \
make ncurses-devel \
openldap openldap-devel openssl openssl-devel pam-devel readline-devel \
vim wget unzip zip zlib zlib-devel

# Ver1.0.1
# - 添加一些 PHP 依赖