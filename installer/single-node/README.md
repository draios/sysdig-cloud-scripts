# Single node POV installer

This script will install docker, minikube, jq, curl etc required to run Sysdig
Platform, after installing all dependencies the script will create a
values.yaml and run the installer using the created values.yaml file.

## Download Installer
Single Node script is integrated into installer. Download/Copy installer binary to get the single node installer script.

Running "installer single-node" creates a install.sh file in current working directory.

```bash
sudo su
#execute permissions for installer installer
chmod u+x installer-linux-amd64
#installer needs to be in PATH
cp installer-linux-amd64 /usr/bin/installer
#get single node installer script
installer single-node
```

## Usage

```bash
sudo ./install.sh
```

## Help

```bash
sudo ./install.sh -h
#prints help
Help...
-a | --airgap-builder to specify airgap builder
-i | --airgap-install to run as airgap install mode
-r | --run-installer  to run the installer alone
-q | --quaypullsecret followed by quaysecret to specify airgap builder
-d | --delete-sysdig deletes sysdig namespace, persistent volumes and data from disk
```

This will prompt for quay pull secrets, sysdig license and domain name(in ec2
this is the public hostname for the instance). It will install dependencies
run the installer and create a sysdig platform. It also logs everything you
see in your terminal to `/var/log/sysdig-installer.log` so this can be used
for debugging a failed install.

## Requirements.

- An instance with at least 16 CPU cores, 32GB of RAM and 300GB of disk space.
- Port 443 and 6443 granted network access (in AWS this is done with security
groups)

## Status

Tested on:
- ubuntu bionic

Should work fine on:
- amazon linux
- centos 7
- debian buster
- debian stretch
- ubuntu xenial

The script will not work on any OS not in above lists.

## Note

To need to run `kubectl` as root on the host.

## Future improvements

- the script will be hosted in a public location so you can `curl | sudo bash`
the script.

# Airgapped pov installer (VMDK images)

The VMDK image distribution was retired in May 2022.
