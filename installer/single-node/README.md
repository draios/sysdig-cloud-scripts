# Single node POV installer

This script will install docker, minikube, jq, curl etc required to run Sysdig
Platform, after installing all dependencies the script will create a
values.yaml and run the installer using the created values.yaml file.

## Usage

Copy the [script](./install.sh) to the machine that sysdig
platform is intended to run on, if you intend using enterprise anchore copy the
anchore license file to the same path as the script, then run:

```bash
sudo ./install.sh
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
- centos 8
- debian buster
- debian stretch
- ubuntu xenial

The script will not work on any OS not in above lists.

## Note

To need to run `kubectl` as root on the host.

## Future improvements

- the script will be hosted in a public location so you can `curl | sudo bash`
the script.

