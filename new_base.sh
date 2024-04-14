#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${red}ERROR: ${plain} Must use root to run this script.\n"
        exit 1
    fi
}

# Check OS
check_os() {
    # OS distro release
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

    # OS arch
    arch=$(arch)
    case "$arch" in
    x86_64 | x64 | amd64)
        arch="amd64"
        ;;
    aarch64 | arm64)
        arch="arm64"
        ;;
    *)
        echo -e "${red}ERROR: ${plain}Unsupported architecture: $arch\n"
        exit 1
        ;;
    esac

    # OS version
    os_version=""
    if [[ -f /etc/os-release ]]; then
        os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
    elif [[ -f /etc/lsb-release ]]; then
        os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
    fi

    if [[ -n "$os_version" ]]; then
        if [[ x"${release}" == x"centos" && ${os_version} -le 7 ]]; then
            echo -e "${red}Please use CentOS 8 or higher version.${plain}\n"
            exit 1
        elif [[ x"${release}" == x"ubuntu" && ${os_version} -lt 16 ]]; then
            echo -e "${red}Please use Ubuntu 16 or higher version.${plain}\n"
            exit 1
        elif [[ x"${release}" == x"debian" && ${os_version} -lt 10 ]]; then
            echo -e "${red}Please use Debian 10 or higher version.${plain}\n"
            exit 1
        fi
    fi

    echo "OS: ${release} ${os_version}"
    echo "Architecture: ${arch}"
}

# Install base packages
install_base_packages() {
    echo -e "${yellow}Installing base packages...${plain}"
    if [[ x"${release}" == x"centos" ]]; then
        yum install -y wget curl git vim tar python3-pip
        if [[ "$arch" == "arm64" ]]; then
            yum install -y python3-pip
        fi
    else
        apt-get update
        apt-get install -y wget curl git vim tar python3-pip
        if [[ "$arch" == "arm64" ]]; then
            apt-get install -y python3-pip libxml2-dev libxslt1-dev zlib1g-dev libffi-dev libssl-dev
        fi
    fi
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1
}

# Install Docker
install_docker() {
    # Check if Docker is already installed
    docker_installed=$(
        docker version &>/dev/null
        echo $?
    )
    if [[ $docker_installed -eq 0 ]]; then
        echo "Docker is already installed."
        return
    fi

    echo -e "${yellow}Installing Docker...${plain}"
    curl -fsSL https://get.docker.com/ | bash
    systemctl enable docker
    systemctl start docker

    # Check if Docker installation was successful
    docker_installed=$(
        docker version &>/dev/null
        echo $?
    )
    if [[ $docker_installed -eq 0 ]]; then
        echo "Docker installed successfully."
    else
        echo -e "${red}Failed to install Docker.${plain}"
        exit 1
    fi

    if [[ x"${release}" == x"ubuntu" ]]; then
        apt-get install -y docker-compose-plugin
    fi
}

# Install Docker Compose
install_docker_compose() {
    # Check if Docker Compose is already installed
    docker_compose_installed=$(
        docker-compose version &>/dev/null
        echo $?
    )
    if [[ $docker_compose_installed -eq 0 ]]; then
        echo "Docker Compose is already installed."
        return
    fi

    echo -e "${yellow}Installing Docker Compose...${plain}"
    docker_compose_version="1.29.2" # Set the desired Docker Compose version here
    if [[ "$arch" == "amd64" ]]; then
        curl -L "https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    elif [[ "$arch" == "arm64" ]]; then
        pip3 install docker-compose
    fi

    # Check if Docker Compose installation was successful
    docker_compose_installed=$(
        docker-compose version &>/dev/null
        echo $?
    )
    if [[ $docker_compose_installed -eq 0 ]]; then
        echo "Docker Compose installed successfully."
    else
        echo -e "${red}Failed to install Docker Compose.${plain}"
        exit 1
    fi
}

# Install Zsh and Oh-My-Zsh
install_zsh_and_oh_my_zsh() {
    # Check if Zsh is already installed
    check_zsh_installed=$(
        zsh --version &>/dev/null
        echo $?
    )
    if [[ $check_zsh_installed -eq 0 ]]; then
        echo "Zsh is already installed."
    else
        echo -e "${yellow}Installing Zsh...${plain}"
        if [[ x"${release}" == x"centos" ]]; then
            yum install -y zsh
        else
            apt-get install -y zsh
        fi
    fi

    # Install Oh-My-Zsh
    echo -e "${yellow}Installing Oh-My-Zsh...${plain}"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Install Zsh plugins and theme
    echo -e "${yellow}Installing Zsh plugins and theme...${plain}"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

    # Enable plugins
    current_plugins=$(grep "plugins=(.*)" ~/.zshrc | grep -v "rail.*" | cut -d "(" -f 2 | cut -d ")" -f 1)
    new_plugins="sudo extract git zsh-autosuggestions zsh-syntax-highlighting"
    sed -i "s/$current_plugins/$new_plugins/" ~/.
    zshrc

    # Install pure theme
    mkdir -p "$HOME/.zsh"
    git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
    echo "fpath+=$HOME/.zsh/pure" >>"$HOME/.zshrc"
    echo "autoload -U promptinit; promptinit" >>"$HOME/.zshrc"
    echo "prompt pure" >>"$HOME/.zshrc"

    # Prompt user to change default shell
    read -r -p "Do you want to change your default shell to Zsh? [y/N] " change_shell
    if [[ $change_shell =~ ^[Yy]$ ]]; then
        chsh -s "$(which zsh)"
        echo -e "${green}Default shell changed to Zsh.${plain}"
    fi

    # Reload shell
    source "$HOME/.zshrc"
}

# Install NVM (Node Version Manager)
install_nvm() {
    # Check if NVM is already installed
    nvm_installed=$(
        nvm --version &>/dev/null
        echo $?
    )
    if [[ $nvm_installed -eq 0 ]]; then
        echo "NVM is already installed."
        return
    fi

    echo -e "${yellow}Installing NVM...${plain}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

    # Set up NVM environment
    load_nvm_env_str='export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm'
    shell_type="$SHELL"
    case "$shell_type" in
    *zsh)
        echo "$load_nvm_env_str" >>"$HOME/.zshrc"
        ;;
    *bash)
        echo "$load_nvm_env_str" >>"$HOME/.bashrc"
        ;;
    *)
        echo -e "${red}Unsupported shell type: $shell_type${plain}"
        ;;
    esac

    # Reload shell
    source "$shell_type"

    # Install latest LTS version of Node.js
    nvm install --lts
}

# Install Rclone
install_rclone() {
    # Check if Rclone is already installed
    rclone_installed=$(
        rclone --version &>/dev/null
        echo $?
    )
    if [[ $rclone_installed -eq 0 ]]; then
        echo "Rclone is already installed."
        return
    fi

    echo -e "${yellow}Installing Rclone...${plain}"
    curl https://rclone.org/install.sh | sudo bash
}

# Install PyEnv
install_pyenv() {
    # Check if PyEnv is already installed
    pyenv_installed=$(
        pyenv --version &>/dev/null
        echo $?
    )
    if [[ $pyenv_installed -eq 0 ]]; then
        echo "PyEnv is already installed."
        return
    fi

    echo -e "${yellow}Installing PyEnv...${plain}"
    apt-get update
    apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

    curl https://pyenv.run | bash

    # Set up PyEnv environment
    pyenv_env_str='export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"'
    shell_type="$SHELL"
    case "$shell_type" in
    *zsh)
        echo "$pyenv_env_str" >>"$HOME/.zshrc"
        ;;
    *bash)
        echo "$pyenv_env_str" >>"$HOME/.bashrc"
        ;;
    *)
        echo -e "${red}Unsupported shell type: $shell_type${plain}"
        ;;
    esac

    # Reload shell
    source "$shell_type"

    # Install Python 3.10.4
    pyenv install 3.10.4
    pyenv global 3.10.4
}

# Main script
check_root
check_os
install_base_packages

# Prompt user to select desired installations
echo -e "${yellow}Select the components you want to install:${plain}"
echo "1) Docker"
echo "2) Docker Compose"
echo "3) Zsh and Oh-My-Zsh"
echo "4) NVM (Node Version Manager)"
echo "5) Rclone"
echo "6) PyEnv"
echo "0) Exit"

read -rp "Enter your choice (comma-separated for multiple selections): " choice

# Install selected components
for selection in $(echo "$choice" | tr ',' ' '); do
    case "$selection" in
    1)
        install_docker
        ;;
    2)
        install_docker_compose
        ;;
    3)
        install_zsh_and_oh_my_zsh
        ;;
    4)
        install_nvm
        ;;
    5)
        install_rclone
        ;;
    6)
        install_pyenv
        ;;
    0)
        echo -e "${yellow}Exiting...${plain}"
        exit 0
        ;;
    *)
        echo -e "${red}Invalid choice: $selection${plain}"
        ;;
    esac
done

echo -e "${green}Installation completed.${plain}"
