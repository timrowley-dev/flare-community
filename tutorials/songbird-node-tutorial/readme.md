### Songbird Node Tutorial

**YouTube Tutorial (AWS)** (Tim Rowley): https://www.youtube.com/watch?v=SD_IMQMGqn4

#### Outline

**[Cloud Compute Examples](#cloud-compute-examples)**
Table of example instances that can be used to run a node on AWS, GCP or Azure.

**[Go Installation](#go-installation)**
Installation [Go](https://golang.org/doc/install) >= 1.16.8 dependency

**[Install Node Dependencies](#install-node-dependencies)**
Installation of remaining node dependencies (GCC, G++ and JQ) using apt install. JQ is not installed by default on all systems and is only used in the nodes start up command to facilitate the retrieval of the bootstrapping node IP.

**[Flare Node Installation](#flare-node-installation)**
Installing the Flare node codebase by cloning from the official repository and building.

**[Flare Node Configuration](#flare-node-configuration-optional)**
(Optional) Create default node configuration file allowing you to adjust settings (ie. change pruning node to archival node, enable/disable APIs, etc.)

**[Run Script Installation](#run-script-installation-optional)**
(Optional) Create a script that contains the nodes start up command using noup to allow liveness when you exit terminal.

**[Systemd Service Installation](#systemd-service-installation-optional)**
(Optional) Install a systemd service template (specific for run script usage) to ensure liveness of node and restart if node process exits and starts node on system boot.

**NOTE**: In descriptions and alias, nodes may be referrenced as a "Flare" node irrespective of the network the node is running.

#### Cloud Compute Examples:

| Cloud Provider | Type              |          Name |
| -------------- | :---------------- | ------------: |
| AWS            | Compute Optimised |    c5.2xlarge |
| GCP            | Compute           | e2-standard-8 |
| Azure          | D-Series          |        D2s_v4 |

#### Go Installation:

1.  Download [Go](https://golang.org/doc/install) (any version >= 1.16.8):
    `wget https://go.dev/dl/go1.16.8.linux-amd64.tar.gz`
2.  Remove any old copies of go and install downloaded version:
    `sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.16.8.linux-amd64.tar.gz`
3.  Add environment variable
    `export PATH=$PATH:/usr/local/go/bin`
4.  You might also need to set GOPATH if build requests it:
    `export GOPATH=$HOME/go`
5.  Reload environments
    `source $HOME/.profile`

#### Install node dependencies:

1.  Update system packages list
    `sudo apt update`
2.  Install build essentials (GCC & G++)
    `sudo apt install build-essential`
3.  Install jq
    `sudo apt install jq`

| :exclamation: From tag v0.6.4 the folder structure has changed from `flare` to `go-songbird/avalanchego` |
| -------------------------------------------------------------------------------------------------------- |

#### Flare Node Installation:

1.  Clone Flare Node repo using latest version tag
    `git clone https://github.com/flare-foundation/go-songbird`
2.  Enter repository directory
    `cd go-songbird`
3.  Switch to latest version
    `git checkout <tag>`
    If tag >=v0.6.4 `cd avalanchego`
4.  Build Node
    `./scripts/build.sh`
5.  Set up [node configuration](#flare-node-configuration-optional) _(Optional)_
6.  Set up [run script](#run-script-installation-optional) and [systemd service](#systemd-service-installation-optional) _(Optional)_
7.  Start node
    a) Run using command found on [Flare repository](https://github.com/flare-foundation/flare#running-flare) for specific network _or_
    b) Start node using the run script setup below using [systemd service](#systemd-service-installation-optional) (ie. `sudo systemctl start flare-node.service`)

#### Flare Node Configuration (Optional):

_By default configuration files are store at `$HOME/.flare/configs/chains`_

1.  Create config file (ie. based on default location: `$HOME/.flare/configs/chains/C/config.json`)
2.  Paste below configuration

```json
{
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
  "pruning-enabled": true,
  "local-txs-enabled": false,
  "api-max-duration": 0,
  "api-max-blocks-per-request": 0,
  "allow-unfinalized-queries": false,
  "allow-unprotected-txs": false,
  "remote-tx-gossip-only-enabled": false,
  "log-level": "info"
}
```

All configurations variables can be found in official [Avalanche documentation](https://docs.avax.network/nodes/maintain/avalanchego-config-flags#c-chain-configs).

#### Run Script Installation (Optional):

1. Copy the contents/file of the run script from [scripts](/tutorials/songbird-node-tutorial/scripts)

- Node Version >= 0.6.4: [run-songbird.sh](/tutorials/songbird-node-tutorial/scripts/run-songbird-v0.6.4.sh)
- Node Version <= 0.6.3: [run-songbird.sh](/tutorials/songbird-node-tutorial/scripts/run-songbird-v0.6.3.sh)

2. Give execution permission by running `chmod +x <script-name>.sh` (ie. `chmod +x run-songbird.sh`)

#### Systemd Service Installation (Optional):

_Requires [run script](#run-script-installation-optional) to be installed or modifed to fit your needs_

1.  Enter text edit into the system services with file name of `songbird-node.service`
    `sudo nano /etc/systemd/system/songbird-node.service`
2.  Paste service template and make any required changes if applicable (ie. working directory, execution path):

```ini
# songbird-service-template.service
# This template requires the run-songbird.sh script
[Unit]
Description=Songbird Systemd Service
StartLimitIntervalSec=0

[Service]
ExecStart=/home/ubuntu/run-songbird.sh
Restart=always
RestartSec=1
WorkingDirectory=/home/ubuntu
Environment=GOPATH=/home/ubuntu/go
Environment=PATH=/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

User=ubuntu
Type=forking

StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=SongbirdNode

[Install]
WantedBy=multi-user.target
```

3. Allow service to start node on system boot up by running `sudo systemctl enable songbird-node.service`

4. Start service (boot up node) `sudo systemctl start songbird-node.service`
