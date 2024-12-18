#!/bin/bash

function install_docker() {

	__besman_echo_no_colour "Checking if Docker is installed..."

	if command -v docker >/dev/null 2>&1; then
		__besman_echo_yellow "Docker is already installed"
		docker --version
	else
		__besman_echo_white "Docker not found. Installing Docker..."

		# Update package index
		sudo apt-get update

		# Install required packages
		sudo apt-get install -y \
			apt-transport-https \
			ca-certificates \
			curl \
			gnupg \
			lsb-release

		# Add Docker's official GPG key
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

		# Set up stable repository
		echo \
			"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

		# Install Docker Engine
		sudo apt-get update
		sudo apt-get install -y docker-ce docker-ce-cli containerd.io

		# Start Docker service
		sudo systemctl start docker
		sudo systemctl enable docker

		# Add current user to docker group
		sudo groupadd docker
		sudo usermod -aG docker $USER
		# newgrp docker


		__besman_echo_yellow "Docker installed successfully!"
		docker --version
	fi
}

function install_docker_compose() {
	__besman_echo_no_colour "Checking if Docker Compose is installed..."

	if command -v docker-compose >/dev/null 2>&1; then
		__besman_echo_yellow "Docker Compose is already installed"
		docker-compose --version
	else
		__besman_echo_white "Docker Compose not found. Installing latest version..."

		# Download the latest version of Docker Compose directly from GitHub releases
		sudo curl -L "https://github.com/docker/compose/releases/download/latest/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

		# check if operation successful
		if [ $? -ne 0 ]; then
			__besman_echo_red "Failed to download Docker Compose."
			return 1
		fi
		# Apply executable permissions
		sudo chmod +x /usr/local/bin/docker-compose

		__besman_echo_yellow "Docker Compose installed successfully!"
		docker compose --version
		if [ $? -ne 0 ]; then
			__besman_echo_red "Failed to download Docker Compose."
			return 1
		fi
	fi
}

# function __beslab_init_OIAB-network()
# {
    #TBD
# }


function __beslab_install_OIAB-network()
{
    if [[ -d $BESMAN_BECKN_ONIX_DIR ]]; then
		__besman_echo_white "Beckn Onix code found"
	else
		__besman_echo_white "Cloning source code repo from $BESLAB_ORG/beckn-onix"
		__besman_repo_clone "$BESLAB_ORG" "beckn-onix" "$BESLAB_ONIX_DIR" || return 1
		cd "$BESLAB_ONIX_DIR" || return 1
	fi
    echo "3" | ./beckn-onix.sh

	if [[ "$?" != "0" ]]; then
		__besman_echo_red "Failed to install using OSSVerse Onix"
		return 1
	else
		__besman_echo_green "Successfully installed the entire network using OSSVerse Onix"
		return 0
	fi
}

function __beslab_uninstall_OIAB-network()
{
    if [[ ! -d $BESLAB_ONIX_DIR ]];
    then
        __besman_echo_red "Onix not installed"
        return 1
    fi

    cd "$BESLAB_ONIX_DIR/install" || return 1

    sudo docker compose -f docker-compose-app.yml -f docker-compose-bap.yml -f docker-compose-bpp-with-sandbox.yml -f docker-compose-gateway.yml -f docker-compose-registry.yml  down --rmi all --volumes >/dev/null 2>&1

    if [[ "$?" != "0" ]]; then
        __besman_echo_red "Failed to uninstall network"
        return 1
    else
        __besman_echo_green "Successfully uninstalled the entire network"
        return 0
    fi
}

function __beslab_plugininfo_OIAB-buyer-ui()
{
	__besman_echo_no_colour "################ Plugin: OIAB-network ################"
	__besman_echo_no_colour "-------------------------------------------------------"
	__besman_echo_no_colour ""
	__besman_echo_no_colour "This plugin installs the following:"
    __besman_echo_no_colour "1. bap client: Takes the requests from buyer app and send it to the network. Running on port 5001."
    __besman_echo_no_colour "2. bap network: Takes the request from the network and sends it to the buyer app. Running on port 5002."
	__besman_echo_no_colour "3. registry: Stores the list of all the participants in the network and their metadata. Runs on port $BESLAB_IP_ADDRESS:3030."
	__besman_echo_no_colour "4. gateway: Broadcasts the search requests to all the matching sellers in the network. Runs on port 4030."
	__besman_echo_no_colour "5. bpp network: Takes in the requests from the network and sends it to seller app. Runs on port 6002."
	__besman_echo_no_colour "6. bpp client: Takes in the requests from the seller app and sends it bpp network. Runs on port 6001."

}