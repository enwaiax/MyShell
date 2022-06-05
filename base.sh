#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
function check_root() {
    [[ $EUID -ne 0 ]] && echo -e "${red}ERROR: ${plain} Must use root to run it.\n" && exit 1
}

# check os
function check_os() {
    # os distro release
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
    fi

    # os arch
    arch=$(arch)
    if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
        arch="amd64"
    elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
        arch="arm64"
    else
        echo -e "${red}ERROR: ${plain}Unsupported architecture: $arch\n" && exit 1
    fi

    # os version
    os_version=""
    if [[ -f /etc/os-release ]]; then
        os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
    fi
    if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
        os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
    fi

    if [[ x"${release}" == x"centos" ]]; then
        if [[ ${os_version} -le 7 ]]; then
            echo -e "${red}Please use CentOS 8 or higher version.${plain}\n" && exit 1
        fi
    elif [[ x"${release}" == x"ubuntu" ]]; then
        if [[ ${os_version} -lt 16 ]]; then
            echo -e "${red}Please use Ubuntu 16 or higher version.${plain}\n" && exit 1
        fi
    elif [[ x"${release}" == x"debian" ]]; then
        if [[ ${os_version} -lt 10 ]]; then
            echo -e "${red}Please Debian 10 or higher version.${plain}\n" && exit 1
        fi
    fi

    echo "OS: ${release} ${os_version}"
    echo "Architecture: ${arch}"
}

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl git vim tar python3-pip -y
        if $arch == "arm64"; then
            yum install python3-pip -y
        fi
    else
        apt install wget curl git vim tar python3-pip -y
        if $arch == "arm64"; then
            apt install python3-pip libxml2-dev libxslt1-dev zlib1g-dev libffi-dev libssl-dev -y
        fi
    fi
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1
}

function install_docker() {
    # check whether docker has been installed
    before_check_docker_installed=$(
        docker version &>/dev/null
        echo $?
    )
    if [[ $before_check_docker_installed -eq 0 ]]; then
        echo "Docker has been installed."
        return
    fi
    echo "Start to install docker..."
    curl -fsSL https://get.docker.com/ | sudo sh
    systemctl enable docker
    systemctl start docker
    after_check_docker_installed=$(
        docker version &>/dev/null
        echo $?
    )
    if [[ $after_check_docker_installed -eq 0 ]]; then
        echo "Install docker successfully."
    else
        echo "Failed to install docker."
        exit 1
    fi
    sudo apt install docker-compose-plugin -y >/dev/null
}

function install_docker_compose() {
    # check whether docker-compose has been installed
    before_check_docker_compose_installed=$(
        docker-compose version &>/dev/null
        echo $?
    )
    if [[ $before_check_docker_compose_installed -eq 0 ]]; then
        echo "Docker-compose has been installed."
        return
    fi
    echo "Start to install docker-compose..."
    if $arch == "amd64"; then
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    elif $arch == "arm64"; then
        pip3 install docker-compose
    fi
    after_check_docker_compose_installed=$(
        docker-compose version &>/dev/null
        echo $?
    )
    if [[ $after_check_docker_compose_installed -eq 0 ]]; then
        echo "Install docker-compose successfully."
    else
        echo "Failed to install docker-compose."
        exit 1
    fi
}

function install_oh_my_zsh() {
    # check whether zsh has been installed
    before_check_zsh_installed=$(
        zsh --version &>/dev/null
        echo $?
    )
    if [[ $before_check_zsh_installed -eq 0 ]]; then
        echo "Zsh has been installed."
        return
    fi
    echo "Start to install zsh..."
    if [[ x"${release}" == x"centos" ]]; then
        yum install zsh -y
    else
        apt install zsh -y
    fi
    chsh -s $(which zsh)
    zsh
    echo "Start to install oh-my-zsh..."
    curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
    echo -e "${yellow}Downloading zsh-autosuggestions...${plain}\n"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    echo -e "${yellow}Downloading zsh-syntax-highlighting...${plain}\n"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    # enable plugins
    a=$(grep "plugins=(.*)" ~/.zshrc | grep -v "rail.*" | cut -d "(" -f 2 | cut -d ")" -f 1)
    b='sudo extract git zsh-autosuggestions zsh-syntax-highlighting'
    sed -i "s/$a/$b/" ~/.zshrc
    # install pure theme
    mkdir -p "$HOME/.zsh"
    git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
    echo "fpath+=$HOME/.zsh/pure" >>"$HOME/.zshrc"
    echo "autoload -U promptinit; promptinit" >>"$HOME/.zshrc"
    echo "prompt pure" >>"$HOME/.zshrc"
    # reload shell
    source ~/.zshrc
}

function install_nvm() {
    # check whether nvm has been installed
    before_check_nvm_installed=$(
        nvm --version &>/dev/null
        echo $?
    )
    if [[ $before_check_nvm_installed -eq 0 ]]; then
        echo "Nvm has been installed."
        return
    fi
    echo "Start to install nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
    load_nvm_env_str='export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm"'
    if [[ $(SHELL) == "/bin/zsh" ]]; then
        echo -e "$load_nvm_env_str" >>~/.zshrc
    elif [[ $(SHELL) == "/bin/bash" ]]; then
        echo -e "$load_nvm_env_str" >>~/.bashrc
    fi
    exec $SHELL
    nvm install --lts
}

function install_rclone() {
    # check whether rclone has been installed
    before_check_rclone_installed=$(
        rclone --version &>/dev/null
        echo $?
    )
    if [[ $before_check_rclone_installed -eq 0 ]]; then
        echo "Rclone has been installed."
        return
    fi
    echo "Start to install rclone..."
    curl https://rclone.org/install.sh | sudo bash
}

function install_pyenv() {
    # check whether pyenv has been installed
    before_check_pyenv_installed=$(
        pyenv --version &>/dev/null
        echo $?
    )
    if [[ $before_check_pyenv_installed -eq 0 ]]; then
        echo "Pyenv has been installed."
        return
    fi
    echo "Start to install pyenv..."
    sudo apt-get update && sudo apt-get install make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev -y >/dev/null
    curl https://pyenv.run | bash
    if [[ $(SHELL) == "/bin/zsh" ]]; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >>~/.zshrc
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >>~/.zshrc
        echo 'eval "$(pyenv init -)"' >>~/.zshrc
    elif [[ $(SHELL) == "/bin/bash" ]]; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >>~/.bashrc
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >>~/.bashrc
        echo 'eval "$(pyenv init -)"' >>~/.bashrc
    fi
    exec $SHELL
    pyenv install 3.10.4
    pyenv global 3.10.4
}
