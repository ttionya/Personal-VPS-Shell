# Personal VPS Shell

### **自用服务器脚本**

#### [upgrade_apache.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/upgrade_apache.sh)
- 仅支持 CentOS 6.X、Apache 2.4、PCRE 1

#### [upgrade_apache_http2.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/upgrade_apache_http2.sh)
- 支持 CentOS 6.X / CentOS 7.X、Apache 2.4、PCRE 1、OpenSSL 1.0.2、nghttp2

#### [upgrade_php.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/upgrade_php.sh)
- 仅支持 CentOS 6.X、PHP 7.0.X / PHP 7.1.X、Apache 2.4、PCRE 1

#### [install_nvm.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/install_nvm.sh)
- 理论支持全部 CentOS 版本，但仅在 CentOS 6.8 下进行过测试
- 涉及 `rm -rf` 命令，操作务必小心
- 已将软件源设为淘宝，歪果仁慎用

#### [install_zsh.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/install_zsh.sh)
- 暂时只支持 yum, apt, zypper, pacman 包管理器

#### [install_docker_ce.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/install_docker_ce.sh)
- 仅支持 CentOS 7
- 低版本内核使用 Device Mapper，高版本内核使用 Overlay2
- 已将软件源设为阿里巴巴，歪果仁慎用

#### [upgrade_kernel.sh](https://raw.githubusercontent.com/ttionya/Personal-VPS-Shell/master/upgrade_kernel.sh)
- 升级 CentOS 7 的内核到 ElRepo 最新内核
- **请勿在生产环境使用**