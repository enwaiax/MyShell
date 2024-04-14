#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

sh_ver="0.0.2"

# 定义颜色变量
red="\033[31m"
green="\033[32m"
yellow="\033[33m"
purple="\033[35m"
reset="\033[0m"

#—————————系统类—————————
#1 安装系统依赖
install_base() {
	apt-get update >/dev/null
	apt-get install -y wget curl git vim sudo net-tools >/dev/null
}

#2 bash补全
bash_completion() {
	apt-get install -y bash-completion
	cp ~/.bashrc ~/.bashrc.bak
	wget https://raw.githubusercontent.com/Chasing66/MyShell/main/files/bashrc && mv bashrc ~/.bashrc
	exec $SHELL
}

#3 更改为中国时区(24h制,重启生效)
set_timezone() {
	sudo timedatectl set-timezone Asia/Shanghai
}

#4 改变 systemlog 大小
change_system_log() {
	sudo sed -i "s/#SystemMaxUse=/SystemMaxUse=10M/g" /etc/systemd/journald.conf
	sudo systemctl restart systemd-journald
}

#5 安装docker
install_docker() {
	curl -sSL https://get.docker.com/ | sh
}

#6 安装fail2ban
install_fail2ban() {
	apt-get install -y fail2ban >/dev/null
	systemctl enable fail2ban
	systemctl start fail2ban >/dev/null
	fail2ban-client status sshd
}

#7 修改vim模式
set_vim_modole() {
	sudo tee /etc/vim/vimrc.local <<EOF
source \$(find / -name defaults.vim)
let skip_defaults_vim = 1
if has('mouse')
    set mouse-=a
endif
EOF
}

#8 安装cerbot
install_cerbot() {
	sudo apt-get install -y snapd >/dev/null
	sudo snap install core
	sudo snap refresh core
	sudo snap install --classic certbot
	sudo ln -s /snap/bin/certbot /usr/bin/certbot
}

#9 oh-my-zsh
install_oh_my_zsh() {
	# 检查 zsh 是否已安装
	zsh --version &>/dev/null
	if [[ $? -eq 0 ]]; then
		echo "Zsh has been installed."
	fi
	echo "Start to install zsh..."
	if [[ "$(
		. /etc/os-release
		echo $ID
	)" == "centos" ]]; then
		sudo yum install -y zsh
	else
		sudo apt install -y zsh
	fi
	chsh -s /bin/zsh "$USER"
	echo "Start to install oh-my-zsh..."
	sh -c "$(curl -fsSL https://install.ohmyz.sh/)"

	echo -e "\n${yellow}Downloading zsh-autosuggestions...${reset}"
	git clone https://github.com/zsh-users/zsh-autosuggestions \
		${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

	echo -e "\n${yellow}Downloading zsh-syntax-highlighting...${reset}"
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
		${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

	# 启用插件
	plugins=$(grep "plugins=(.*)" ~/.zshrc | grep -v "rail.*" | cut -d "(" -f 2 | cut -d ")" -f 1)
	new_plugins="sudo z extract git zsh-autosuggestions zsh-syntax-highlighting"
	sed -i "s/$plugins/$new_plugins/" ~/.zshrc

	# 安装 pure 主题
	mkdir -p "$HOME/.zsh"
	git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
	echo "fpath+=$HOME/.zsh/pure" >>"$HOME/.zshrc"
	echo "autoload -U promptinit; promptinit" >>"$HOME/.zshrc"
	echo "prompt pure" >>"$HOME/.zshrc"

	# 重新加载 shell
	source ~/.zshrc
}

setup_ssh_key() {
	read -rp "Enter your SSH public key: " ssh_key
	mkdir -p ~/.ssh
	echo "$ssh_key" >>~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys
}

#—————————代理类—————————
#11 xray
install_xray() {
	bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u root
}

#—————————加速类—————————
#21 bbr
set_bbr() {
	bash -c "$(curl -sSL https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcp.sh)"
}

echo -e "
+-------------------------------------------------------------+
|                          懒人专用                           |
|                 Linux一键管理脚本 ${red}[v${sh_ver}]${reset}                  |
|                     一键在手Linux无忧                       |
|                     欢迎提交一键脚本                        |
+-------------------------------------------------------------+

 —————————系统类—————————
 ${green}1.${reset} 安装系统依赖
 ${green}2.${reset} bash补全
 ${green}3.${reset} 更改为中国时区
 ${green}4.${reset} 改变systemlog日志大小
 ${green}5.${reset} 安装docker
 ${green}6.${reset} 安装fail2ban
 ${green}7.${reset} 修改vim编辑模式
 ${green}8.${reset} 安装cerbot
 ${green}9.${reset} 安装oh-my-zsh
 ${green}10.${reset} 设置ssh 免密登录
 —————————代理类—————————
 ${green}11.${reset} 安装xray
 —————————加速类—————————
 ${green}21.${reset} bbr加速
"

read -rp " 请输入数字: " num
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
8)
	install_cerbot
	;;
9)
	install_oh_my_zsh
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
