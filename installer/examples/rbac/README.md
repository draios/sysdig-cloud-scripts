# RBAC for Installer (work in progress) v0.0.0a

- RBAC resources required to run the `installer`

- each of the three directories contains YAMLs for a specific case:

[readonly](readonly)
- readonly access to the namespace and minimal resources necessary for the installer to 
  `generate` and `secure-diff` the existing install (or for a new install)

[external-ingress](external-ingress)
- more restrictive RBAC access rights by using an external `ingress` object
- TBD
  
[fullaccess](fullaccess)
- allows the execution of `installer` as-is, including rights for `StorageClass` and `IngressController`

[openshift](openshift)
- TBD

## Instructions

- for each usecase we provide YAMLs to create the necessary RBAC resources

- this example assumes that Sysdig will be installed in the `sysdigcloud` namespace

- apply these YAMLs to your cluster from an `admin` level account

- create a `kubeconfig` for the ServiceAccount installer

- use the `kubeconfig` to execute the installer
