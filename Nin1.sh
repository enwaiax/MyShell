#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

sh_ver="0.0.1"

FontColor_Red="\033[31m"
FontColor_Red_Bold="\033[1;31m"
FontColor_Green="\033[32m"
FontColor_Green_Bold="\033[1;32m"
FontColor_Yellow="\033[33m"
FontColor_Yellow_Bold="\033[1;33m"
FontColor_Purple="\033[35m"
FontColor_Purple_Bold="\033[1;35m"
FontColor_Suffix="\033[0m"

#—————————系统类—————————
#1 安装系统依赖
install_base(){
	apt update >/dev/null
    apt install wget curl git vim tar python3-pip sudo -y
}
#2 bash补全
bash_completion(){
	apt install bash-completion
	wget https://raw.githubusercontent.com/Chasing66/MyShell/main/files/bashrc && mv bashrc ~/.bashrc
	exec $SHELL
}
#3 更改为中国时区(24h制,重启生效)
set_timezone(){
    sudo timedatectl set-timezone Asia/Shanghai
}

#4 改变 systemlog 大小
change_system_log()
{
	sed -i "s/#SystemMaxUse=/SystemMaxUse=10M/g" /etc/systemd/journald.conf
	sudo systemctl restart systemd-journald
}

#5 安装docker
install_docker(){
	curl -sSL https://get.docker.com/ | sh
}

#6 安装fail2ban
install_fail2ban(){
	apt install fail2ban -y >/dev/null
	systemctl enable fail2ban
	systemctl start fail2ban >/dev/null
	fail2ban-client status sshd
}

#7 修改vim模式
set_vim_modole(){
	tee /etc/vim/vimrc.local  << EOF
source $(find / -name defaults.vim)
let skip_defaults_vim = 1
if has('mouse')
    set mouse-=a
endif
EOF
}

#—————————代理类—————————
#11 xray
install_xray(){
	bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root
}

#—————————加速类—————————
#21 bbr
set_bbr(){
	bash -c "$(curl -sSL https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcp.sh)"
}

echo -e " 
+-------------------------------------------------------------+
|                          懒人专用                           |
|                 小鸡一键管理脚本 ${FontColor_Red}[v${sh_ver}]${FontColor_Suffix}                   |                      
|                     一键在手小鸡无忧                        |
|                     欢迎提交一键脚本                        |
+-------------------------------------------------------------+

  
 —————————系统类—————————
 ${FontColor_Green} 1.${FontColor_Suffix} 安装系统依赖
 ${FontColor_Green} 2.${FontColor_Suffix} bash补全
 ${FontColor_Green} 3.${FontColor_Suffix} 更改为中国时区
 ${FontColor_Green} 4.${FontColor_Suffix} 改变systemlog日志大小
 ${FontColor_Green} 5.${FontColor_Suffix} 安装docker
 ${FontColor_Green} 6.${FontColor_Suffix} 安装fail2ban
 ${FontColor_Green} 7.${FontColor_Suffix} 修改vim编辑模式
 —————————代理类—————————
 ${FontColor_Green} 11.${FontColor_Suffix} 安装xray
 —————————加速类—————————
 ${FontColor_Green} 21.${FontColor_Suffix} bbr加速"

unset num
read -e -p " 请输入数字:" num
case "$num" in
	1)
	install_base
	;;
	2)
	bash_completion
	;;
	3)
	set_timezone
	;;
	4)
	change_system_log
	;;
	5)
	install_docker
	;;
	6)
	install_fail2ban
	;;
	7)
	set_vim_modole
	;;	
	11)
	install_xray
	;;
	21)
	set_bbr
	;;
	*)
	echo "请输入正确数字 [0-45]"
	;;
esac