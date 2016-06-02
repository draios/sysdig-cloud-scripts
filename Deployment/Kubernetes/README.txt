Here are two example sysdig.yaml files that can be used to automatically deploy the Sysdig Cloud agent container across a Kubernetes cluster.

The recommended method is using daemon sets - minimum kubernetes version 1.1.1.

If daemon sets are not available, then the replication controller method can be used. This is based on this hack:
https://stackoverflow.com/questions/33377054/how-to-require-one-pod-per-minion-kublet-when-configuring-a-replication-controll/33381862#33381862 

Please see the Sysdig Cloud support site for full documentation:
http://support.sysdigcloud.com/hc/en-us/sections/200959909-Agent-Installation