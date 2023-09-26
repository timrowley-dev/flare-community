#!/bin/bash

# Script: Install Flare Node
# Description: Installs Flare node and dependencies
# Author: Tim Rowley
# Date: 28 Aug 2023


# Lists available node versions
list_versions () {
   echo "Node ($nodeNameKebab) Versions:"
   curl -sL "https://api.github.com/repos/flare-foundation/$nodeNameKebab/tags" \
      | jq -r '.[].name' \
      | head -n 10 \
      | sed 's/^/- /'  \
      | awk 'NR==1 {print $0 " (latest)"}; NR>1 {print}'
}

# Creates service file to run node 
create_service_file () {

   remove_service_file

   echo "Creating service file..."
   rm -f "$nodeName.service"

   execCommand=$(create_node_runner_script)

   echo "[Unit]">>"$nodeName.service"
   echo "Description="$nodeName Systemd Service">>$nodeName.service"
   echo "StartLimitIntervalSec=0">>"$nodeName.service"
   echo "[Service]">>"$nodeName.service"
   echo "Type=simple">>"$nodeName.service"
   echo "User=$(whoami)">>"$nodeName.service"
   echo "WorkingDirectory=$HOME">>"$nodeName.service"
   echo "ExecStart=$execCommand">>"$nodeName.service"
   echo "LimitNOFILE=32768">>$nodeName.service
   echo "Restart=always">>"$nodeName.service"
   echo "RestartSec=1">>"$nodeName.service"
   echo "[Install]">>"$nodeName.service"
   echo "WantedBy=multi-user.target">>"$nodeName.service"
   echo "">>"$nodeName.service"
   chmod 644 "$nodeName.service"
   sudo cp -f "$nodeName.service" "/etc/systemd/system/$nodeName.service"
   sudo systemctl daemon-reload
   rm -f "$nodeName.service"
}

create_config_file () {
   echo "Creating Flare config files..."

   commaAdd=""
   if [ -n "$dbDirParam" ]; then commaAdd=","; fi
   if [ -n "$publicIpParam" ]; then publicIpParam=$(dig +short myip.opendns.com @resolver1.opendns.com); fi
   if [ "$httpHostParam" == "internal" ]; then httpHostParam=$(hostname -I | awk '{print $1}'); fi
   # Node Config   
   rm -f node.json
   echo "{" >>node.json
   echo "  \"public-ip\": \"$publicIpParam\",">>node.json
   echo "  \"http-host\": \"$httpHostParam\"$commaAdd">>node.json
   if [ -n "$dbDirParam" ]; then
      echo "  \"db-dir\": \"$dbDirParam\"">>node.json
   fi
   echo "}" >>node.json
   mkdir -p "$dataDirParam/configs"
   cp -f node.json "$dataDirParam/configs/node.json"

   # C Chain Config
   json_content='{
   "snowman-api-enabled": false,
   "coreth-admin-api-enabled": false,
   "eth-apis": [
      "public-eth",
      "public-eth-filter",
      "net",
      "web3",
      "internal-public-eth",
      "internal-public-blockchain",
      "internal-public-transaction-pool"
   ],
   "rpc-gas-cap": 50000000,
   "rpc-tx-fee-cap": 100,
   "local-txs-enabled": false,
   "api-max-duration": 0,
   "api-max-blocks-per-request": 0,
   "allow-unfinalized-queries": false,
   "allow-unprotected-txs": false,
   "remote-tx-gossip-only-enabled": false,
   "log-level": "info",'
   echo "$json_content" > config.json
   echo "   \"pruning-enabled\": $pruningEnabledParam">>config.json
	echo "}" >>config.json 

   # Write JSON content to config.json
   mkdir -p "$dataDirParam/configs/chains/C"
   cp -f config.json "$dataDirParam/configs/chains/C/config.json"
   rm -f config.json
}

install_go () {
   wget https://go.dev/dl/go1.18.5.linux-amd64.tar.gz
   sudo rm -rf /usr/local/go
   sudo tar -C /usr/local -xzf go1.18.5.linux-amd64.tar.gz
   rm -f go1.18.5.linux-amd64.tar.gz
   export PATH=$PATH:/usr/local/go/bin
   export GOPATH=$HOME/go # Required for go-songbird build
   echo "Go 1.18.5 has been installed."
}

install_dependencies () {
   echo "Installing dependencies..."
   
   version_file="/usr/local/go/VERSION"
   if [[ -f "$version_file" ]]; then
    # Read the content of the VERSION file into a variable
    go_version=$(cat "$version_file")
    
    # Compare version using semantic versioning comparison
      if [[ "$(printf '%s\n' "$go_version" "go1.18.5" | sort -V | head -n1)" == "go1.18.5" ]]; then
         echo "Go version is $go_version or greater."
      else
         echo "Go version is less than go1.18.5. Installing..."
         install_go
      fi
   else
      echo "Go version file not found. Installing..."
      install_go
   fi

   sudo apt update
   sudo apt install build-essential -y
   sudo apt install jq -y
}

# Runs clone and build of node (called from install())
install_flare_node () {
   echo "Installing $networkParam node..."
   git clone https://github.com/flare-foundation/$nodeNameKebab.git
   cd "$nodeNameKebab/avalanchego" || { echo "Git clone failed."; exit 0; }
   git checkout "$nodeVersionParam"
   ./scripts/build.sh
}

# Runs installation script for node
install () {
   
   # Check for existing installation
   if test -f "/etc/systemd/system/$nodeName.service"; then
      echo "Found existing installation of $nodeName. Cancelling installation."
      echo "Service file at: /etc/systemd/system/$nodeName.service"
      echo "Upgrade node using --upgrade <args> command."
      exit 1
   fi

   install_dependencies # including jq for version check
   response_code=$(curl -sL -w "%{http_code}" -o /dev/null "https://$networkParam.flare.network")

   # Check if the response code is 403
   if [ "$response_code" -eq 403 ]; then
      if [ "$networkParam" == "songbird" ]; then 
         public_ip=$(curl -sL ipinfo.io/ip)
         echo "Songbird requires IP whitelisting."
         echo "It appears your IP $public_ip is not whitelisted."
         echo ""
         echo "Read more here: https://docs.flare.network/infra/observation/deploying/#2-songbird-node-whitelisting"
         echo ""
      fi
      echo "URL https://$networkParam.flare.network returned a 403 Forbidden error."
      exit 1
   fi

   api_url="https://api.github.com/repos/flare-foundation/$nodeNameKebab/tags"

   versions=($(curl -sL "$api_url" | jq -r '.[].name'))

   version_found=false

   # Loop through the versions array
   for version in "${versions[@]}"; do
      if [[ "$version" == "$nodeVersionParam" ]]; then
         version_found=true
         break
      fi
   done

   $version_found || { echo "Provided version $nodeVersionParam cannot be found."; list_versions; exit 1; }

	export PATH=$PATH:/usr/local/go/bin # Force go to be available

   if [ -z "$nodeVersionParam" ]; then
    echo "Node version must be specifed using '--version <version>'."
    exit 1
   fi


	if [ -z "$httpHostParam" ]; then
		while true; do
			read -p "Enter http-host (leave blank for default 127.0.0.1): " httpHostParam
			break
		done
	fi

	echo ""
	echo "RPC requests will only be accepted from $httpHostParam - ensure firewall is correctly configured if node is public facing."
	echo ""
   echo "Node version: $nodeVersionParam"
   echo "Pruning enabled: $pruningEnabledParam"
   echo "Public or Private: $httpHostParam"
   echo "DB directory: $dbDirParam"
	echo ""

   install_flare_node
   create_config_file
   create_service_file
   echo "Starting $networkParam node..."
   sudo systemctl daemon-reload
   sudo systemctl start $nodeName
   sudo systemctl enable $nodeName
   
   echo ""
   echo "Data directory: $dataDirParam"
   echo "DB directory: $dbDirParam"
   echo "== Node installation complete. =="
}

upgrade_flare_node () {
   export PATH=$PATH:/usr/local/go/bin # Force go to be available
   cd "$nodeNameKebab/avalanchego" || { echo "$nodeNameKebab not found, ensure flare.sh is in same directory as $nodeNameKebab.."; exit 0; }

   latest_tag=$(curl -sL "https://api.github.com/repos/flare-foundation/$nodeNameKebab/releases" | jq -r '.[0].tag_name')
   current_tag=$(git describe --tags --abbrev=0)

   if [[ "$latest_tag" == "$current_tag" ]]; then
      { echo "Already on latest version"; exit 1; }
   fi

   echo "Upgrading $nodeNameKebab from $current_tag to $latest_tag"
   read -r -p "Are you sure you want to proceed? (y/n): " answer

   if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
      echo "Stopping $nodeName"
      sudo systemctl stop $nodeName

      git pull origin main
      git checkout "$latest_tag"
      ./scripts/build.sh
      echo "Installed $nodeNameKebab $(git describe --tags --abbrev=0)"
      echo "Starting Flare node..."
      sudo systemctl daemon-reload
      sudo systemctl start $nodeName
   else
      echo "Upgrade canceled."
   fi
}

remove_node () {
   echo ""
   echo "This will remove the binary ($nodeNameKebab) and systemd service files"
   echo "but will retain $dataDirParam (including your database)."
   echo ""
   read -p "Are you sure you want to proceed? (y/n): " answer

   if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
      echo "Removing the service..."
      sleep 2
      remove_service_file
      echo "Removing node binaries $HOME/$nodeNameKebab..."
      rm -rf "$HOME/${nodeNameKebab:?}"
      echo "Done."
      echo ""
      echo "$nodeNameKebab removed. Working directory $dataDirParam) has been preserved."
   else
      echo "Action canceled."
   fi
}

# Utility of remove_node
remove_service_file () {
  if test -f "/etc/systemd/system/$nodeName.service"; then
    sudo systemctl stop $nodeName
    sudo systemctl disable $nodeName
    sudo rm /etc/systemd/system/$nodeName.service
  fi
}

# Function to get health status and connected peers
get_health_status () {
    curl_health=$(curl -s http://localhost:9650/ext/health)
    healthy_value=$(echo "$curl_health" | jq -r '.healthy')
    connected_peers_value=$(echo "$curl_health" | jq -r '.checks.network.message.connectedPeers')

    curl_version=$(curl -s --location 'http://localhost:9650/ext/info' --header 'Content-Type: application/json' --data '{"jsonrpc":"2.0","id":1,"method":"info.getNodeVersion","params" :[]}')
    node_verson=$(echo "$curl_version" | jq -r '.result.version')
    
    echo "Healthy: $healthy_value"
    echo "Connected Peers: $connected_peers_value"
    echo "Node Version: $node_verson"
}

create_node_runner_script () {
   # Define the path where you want to create the bootstrap_runner.sh script
   SCRIPT_DIR="$(realpath "$(dirname "$0")")"
   SCRIPT_PATH="$SCRIPT_DIR/node_runner.sh"

# Create the bootstrap_runner.sh script with the necessary content
cat << EOF > "$SCRIPT_PATH"
#!/bin/bash

# DO NOT REMOVE OR MOVE THIS SCRIPT - REQUIRED FOR SYSTEMD SERVICE

bootstrapIds=\$(curl -m 10 -sX POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeID" }' -H 'content-type:application/json;' https://$networkParam.flare.network/ext/info | jq -r ".result.nodeID")
bootstrapIps=\$(curl -m 10 -sX POST --data '{ "jsonrpc":"2.0", "id":1, "method":"info.getNodeIP" }' -H 'content-type:application/json;' https://$networkParam.flare.network/ext/info | jq -r ".result.ip")

execDir="avalanchego" # go-flare is 'avalanchego', go-songbird is 'flare'

if [ "$networkParam" == "songbird" ]; then execDir="flare"; fi

execCommand="$HOME/$nodeNameKebab/avalanchego/build/\$execDir --network-id=$networkParam --bootstrap-ips="\$bootstrapIps" --bootstrap-ids="\$bootstrapIds" --config-file=$dataDirParam/configs/node.json"

if [ "$networkParam" == "flare" ]; then execCommand+=" --data-dir=$dataDirParam"; fi # data-dir only available on goflare


# Execute the main command
\$execCommand
EOF

   # Make the created bootstrap_runner.sh script executable
   chmod +x "$SCRIPT_PATH"
   echo "$SCRIPT_PATH"
}

# Prints usage commands
usage () {
  echo "Usage: $0 [ --help | --version <tag> | --http-host <ip> | --db-dir <path> | --archival ] [ --list | --install | --upgrade  | --remove | --status ]"
  echo "Options:"
  echo "   --help            			Shows this message"
  echo "   --version <tag>          Installs <tag> version, default is the latest"
  echo "   --http-host <ip>  			The accepted interface for RPC requests on port 9650"
  echo "   --db-dir <path>          Full path to the database directory, defaults to $HOME/<.avalanchego | .flare>/db"
  echo "   --archival               If provided, will disable state pruning, defaults to pruning enabled"
  echo ""
  echo "   --list            			Lists latest versions available to install"
  echo "   --install         			Installs node with provided version (see --version && --list)"
  echo "   --upgrade         			Upgrades go-flare to latest tag version available"
  echo "   --remove         			Removes goflare/gosongbird and service files"
  echo "   --status         			Gives current health state and peers of locally running node"
  echo ""
  echo "Example Usage: \"./flare.sh --version v1.7.1805 --http-host 0.0.0.0 --db-dir $HOME/mydb --network flare --install\""
  exit 0
}

check_network_provided () {
   if [ -z "$networkParam" ]; then { echo "Must provide network using '--network <flare | gosongbird>'"; exit 1; }; fi
}

# Check if jq is installed
check_jq_installed () {
   if ! command -v jq &> /dev/null; then
            echo "Installing jq package..."
            
            # Install jq on Ubuntu
            sudo apt-get update
            sudo apt-get install -y jq

            # Check if installation was successful
            if [ $? -eq 0 ]; then
               echo ""
               echo "jq has been successfully installed."
               echo ""
            else
               echo "Installation of jq failed. Please install it manually."
               exit 1
            fi
   fi
}

nodeVersionParam=""
pruningEnabledParam="true"
httpHostParam=""
publicIpParam=""
dbDirParam=""
networkParam=""
dataDirParam=""   # Can only be set as a param for goflare

nodeName=""       # goflare | gosongbird
nodeNameKebab=""  # go-flare | go-songbird

# Process command-line options
while [[ $# -gt 0 ]]; do
   key="$1"
   case $key in
      --network)              # VARIABLE
         networkParam="$2"
         if [ "$networkParam" == "flare" ]; then
            nodeName="goflare"
            nodeNameKebab="go-flare"
            dataDirParam="$HOME/.avalanchego"
         elif [ "$networkParam" == "songbird" ]; then
            nodeName="gosongbird"
            nodeNameKebab="go-songbird"
            dataDirParam="$HOME/.flare"
         else
            echo "Network must be 'goflare' or 'gosongbird'"
            exit 1
         fi
         shift 
         shift 
         ;;
      --version)              # VARIABLE
         nodeVersionParam="$2"
         shift 
         shift
         ;;
      --public-ip)            # VARIABLE
         publicIpParam="$2"
         shift 
         shift 
         ;;
      --http-host)            # VARIABLE
         httpHostParam="$2"
         shift 
         shift 
         ;;
      --db-dir)               # VARIABLE
         dbDirParam="$2"
         shift 
         shift
         ;;
      --archival)             # VARIABLE
         pruningEnabledParam="false"
         shift 
         ;;
      --help)                 # FUNCTION
         usage
         ;;
      --list)                 # FUNCTION
         check_network_provided
         check_jq_installed
         list_versions
         shift 
         ;;
      --install)              # FUNCTION
         check_network_provided
         install
         shift 
         ;;
      --upgrade)              # FUNCTION
         check_network_provided
         upgrade_flare_node
         shift 
         ;;
      --remove)               # FUNCTION
         check_network_provided
         remove_node
         exit 0
         ;;
      --recreate-service-file)               # FUNCTION
         create_service_file
         exit 0
         ;;
      --status)               # FUNCTION
         get_health_status
         exit 0
         ;;
      *)
         # Unknown option
         echo "Unknown option: $1"
         exit 1
         ;;
   esac
done