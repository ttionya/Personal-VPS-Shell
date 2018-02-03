# Personal VPS Shell

### **自用服务器脚本**

#### [install_apache_http2.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/install_apache_http2.sh)
- 支持 CentOS 7.X、Apache 2.4、PCRE 1、OpenSSL 1.0.2、nghttp2

#### [upgrade_apache_http2.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/upgrade_apache_http2.sh)
- 支持 CentOS 6.X / CentOS 7.X、Apache 2.4、PCRE 1、OpenSSL 1.0.2、nghttp2

#### [upgrade_php.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/upgrade_php.sh)
- 仅支持 CentOS 6.X、PHP 7.0.X / PHP 7.1.X、Apache 2.4、PCRE 1

#### [install_nvm.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/install_nvm.sh)
- 支持 RH / CentOS 6.X / 7.X
- 涉及 `rm -rf` 命令，操作务必小心
- 已将软件源设为淘宝

#### [install_zsh.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/install_zsh.sh)
- 暂时只支持 yum, apt, zypper, pacman 包管理器

#### [install_python3.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/install_python3.sh)
- 仅支持 RH / CentOS 7.X

#### [install_git.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/install_git.sh)

#### [install_docker_ce.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/install_docker_ce.sh)
- 仅支持 CentOS 7
- 低版本内核使用 Device Mapper，高版本内核使用 Overlay2
- 已将软件源设为阿里巴巴

#### [upgrade_kernel.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/upgrade_kernel.sh)
- 仅支持 CentOS 7
- 设置为国内服务器会将 ElRepo 软件源设为清华大学源
- **请勿在生产环境使用**

#### [upgrade_apache.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/upgrade_apache.sh)（已废弃）
- 仅支持 CentOS 6.X、Apache 2.4、PCRE 1