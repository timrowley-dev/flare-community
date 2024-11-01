# Go-Flare Helper Script

The _Go-Flare Installer Script_ is designed to assist in installing a Flare (including Songbird & testnets) node and upgrade it with a single command. To simplify the installation, this script uses Docker and the containe rimages provided by the [Flare Foundation repository](https://hub.docker.com/r/flarefoundation/go-flare/tags).

Note: This script is not fully developed - some features might not work as expected.

What this script does:

- Installs JQ (for parsing JSON)
- Installs Docker
- Configures directories for configuration and logs
- Downloads the Flare node container image and runs it using Docker


## Example Usage

This script is designed and tested on Ubuntu 20.04 and assumes an install will be made to a user directory ($HOME). Script uses sudo commands. Don't forget to make teh script executable with `chmod +x install-flare-docker.sh`.

The version parameter should be the repository name and tag name (e.g. `go-flare:v1.7.1805` or `go-flare:v0.6.6-songbird`). Note: Both Flare and Songbird (including testnets) are in the `goflare` repository as of November 2024.

```
Usage: /.flare.sh [ --help | --version <tag> | --http-host <ip> | --db-dir <path> | --archival ] [ --list | --install | --upgrade  | --remove | --status ]
Options:
   --version <tag>            Installs <tag> version, default is the latest
   --http-host <ip>  			The accepted interface for RPC requests on port 9650
   --db-dir <path>            Full path to the database directory (required)
   --archival                 If provided, will disable state pruning, defaults to pruning enabled
   --install                  Installs node with provided version (see --version && --list)
   --status                   Gives current health state, peers and version of locally running node

Example Usage:

Example Usage to install a specific version, http-host & db-dir:
`./install-flare-docker.sh --version go-flare:v1.7.1805 --http-host 0.0.0.0 --db-dir $HOME/mydb --install`
```

