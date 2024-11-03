# Flare Node Installer Script

**WARNING: READ FIRST**
- For automated pipelines, make a private copy of any scripts you use, never pull from a public repository in automated setups. 
- The script also installs a default configuration, this should be carefully review in the script before installation, especially for validator nodes (default to enabling only web3 & net for validator nodes, for regular nodes a broader set of API's are enabled).

The *Flare Node Installer Script* is designed to assist in installing a Flare (including Songbird & testnets) node and upgrade it with a single command. To simplify the installation, this script uses Docker and the container images provided by the [Flare Foundation repository](https://hub.docker.com/r/flarefoundation/go-flare/tags).

What this script does:

- Installs JQ (for parsing JSON)
- Installs Docker
- Configures directories for configuration and logs
- Downloads the Flare node container image and runs it using Docker


## Example Usage

This script is designed and tested on Ubuntu 20.04 and assumes an install will be made to a user directory ($HOME). Script uses sudo commands. Don't forget to make the script executable with `chmod +x install-flare-docker.sh`.

The version parameter should be the repository name and tag name (e.g. `go-flare:v1.7.1805`, `go-flare:v0.6.6-songbird` or `go-flare:v0.6.6-coston`). Note: Both Flare and Songbird (including testnets) are in the [flare-foundation/go-flare](https://github.com/flare-foundation/go-flare) repository as of November 2024.


**Important notes for validator node installation:**
- The script will create a staking keys directory and use a stricter C Chain configuration. 
- It's suggested to run the script without the `--validator` flag on first installation to bootstrap the node, then run again with the `--validator` flag to create the staking keys directory and run a final time with the keys provided to start the validator. 

**Other tips & tricks:**
- When installing on a cloud platform, it's reccomended to create an additional mounted disk for the database to prevent running out of space on the root disk and to be able to make transportable snapshots.
- When snapshotting, copying or otherwise interacting with the nodes database files, it's highly recommended to stop the node before doing so to prevent corruption.
- A general guide for machine specifications can be found in [Flare's documentation: GCP Marketplace Nodes](https://dev.flare.network/run-node/gcp-marketplace-nodes).
   - GCP Compute Instances: N2D Machines with Balanced Persistent Disks are recommended.

**Important Links:**
- [Flare Node Docker Repository](https://hub.docker.com/r/flarefoundation/go-flare/tags)
- [Flare Node Github Repo](https://github.com/flare-foundation/go-flare)
- [Flare Node Documentation](https://dev.flare.network/run-node/rpc-node)
- [Avalanche C Chain Config](https://docs.avax.network/nodes/chain-configs/c-chain)
```
Usage: /.install-flare-docker.sh [ --network <network> | --version <tag> | --http-host <ip> | --db-dir <path> | [--archival | --validator] ] [--install | --status ]
Options:
   --network <network>        The network to install
   --version <tag>            Installs <tag> version, default is the latest
   --http-host <ip>           The accepted interface for RPC requests on port 9650
   --db-dir <path>            Full path to the database directory (required)
   --archival                 If provided, will disable state pruning, defaults to pruning enabled
   --validator                If provided, will use stricter C chain config and create staking keys directory
   --install                  Installs node with provided version (see --version && --list)
   --status                   Gives current health state, peers and version of locally running node

Example Usage:

```
Example Usage to install a specific version, http-host & db-dir:
`./install-flare-docker.sh --network flare --version go-flare:v1.7.1807 --http-host 0.0.0.0 --db-dir $HOME/mydb --install`

