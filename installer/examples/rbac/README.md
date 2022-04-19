# RBAC for Installer

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
- same base of `fullaccess` with some ocp specific bindings: the scc ones that give the installer the power of running `oc adm policy add-scc-to-user <scc> <installer-sa>`. Please be aware that this example will not work with openshift 3.11, in that case you need to create the scc roles first (with `use` as verb)

[openshift-pgha](openshift-pgha)
- same of `openshift` but the installer sa has more grants since it need to create a clusterroles for the zalando postgres operator service account.

[openshift-nopgha-noagent](openshift-nopgha-noagent)
- openshift case where we don't need rbac to deploy the agent since is done externally to the installer and we already have a zalando postgres operator installed so we just need to use it.

## Instructions

- for each usecase we provide YAMLs to create the necessary RBAC resources

- this example assumes that Sysdig will be installed in the `sysdigcloud` namespace

- apply these YAMLs to your cluster from an `admin` level account

- create a `kubeconfig` for the ServiceAccount installer

- use the `kubeconfig` to execute the installer

- protip: if you have the openshift binary installed you can just use `oc serviceaccounts create-kubeconfig installer` and this will create the serviceaccount kubeconfig for you
