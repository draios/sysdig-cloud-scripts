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

Copy the [script](./install.sh) to the machine that sysdig
platform is intended to run on, then run:

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


# Airgapped pov installer

The airgapped image is built off a debian 9 base image.

The vdmk images are present in s3://sysdig-installer/debian s3 bucket in draios-dev account in us-east.

## Installation

The vmdk image specified above can be imported using the import external hard disk option.

The cpu, memory and disk requirements are 16cpu, 32gig and 60 gig.

## Credentials

The image is built user `sysdig` user with `sysdig` password and sudo access.

## Running installer

After logging in use the above credentials to run the pov installer in airgapped mode.

```bash
  #enter sysdig password `sysdig`
  sudo su
  #start installation in airgapped mode -i in short
  ./install.sh --airgap-install
```

## Gotchas

Initial copy into datastore lists the image as ~5Gig. A recopy into another folder sets the correct size to ~60gig.

## Sharing Image

The objects can exposed by pre-signing with an expiry token using aws cli.

```bash
aws s3 presign --expires-in 86400 s3://sysdig-installer/debian/<RELEASE-TAG>/<IMAGE_NAME>.vmdk
```

The above command produces a pre-signed url which expires in 1 day (60 * 60 * 24 = 86400). Download example below.

```bash
URL="https://sysdig-installer.s3.amazonaws.com/debian/<RELEASE-TAG>/<IMAGE_NAME>UR.vmdk?AWSAccessKeyId=<REDACTED>&Expires=1581191285&Signature=esNl8e7LLwVdNVS4FCBYSTZhJgg%3D" ; wget ${URL}
```

## Exporting as ovf

Use ovftool command line tool to convert vmdk into ovf from <https://www.vmware.com/support/developer/ovf/>.

A example vmx_template.vmx file in installer/single-node/.

Edit setting `nvme0:0.fileName = "/tmp/ovf/sysdig-pov-image.vmdk"` in vmx_template to point to vmdk file.

Running this will create a sysdig-pov-image.ovf.

```bash
ovftool -st=VMX /tmp/ovf/vmx_template.vmx sysdig-pov-image.ovf
```

Enable verbose logging and stdout.

```bash
ovftool --X:logToConsole --X:logLevel=verbose -st=VMX /tmp/ovf/vmx_template.vmx sysdig-pov-image.ovf
```