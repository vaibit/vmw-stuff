**BASIC INFORMATION**

    kubectl get nodes      #- NotReady?  - systemctl restart kubelet
    ~~systemctl restart kubelet --> fix if cant connect to UI~~  check first why k8s is not working:
    docker ps -a | grep kube-api
    docker ps -a | grep etcd
    systemctl status docker


    kubectl cluster-info
    kubectl describe node
    
    kubectl get pod --all-namespaces
    kubectl top pods --all-namespaces
    kubectl get pods -n prelude
    kubectl get pods -n prelude -o wide --> to see the node where each pod is attached
    vamicli version --appliance
    vracli log-bundle --include-cold-storage
    helm -ls (to see if its deployed)
    
    
    
    journalctl -xeu docker
    journal log cleanup 

Retain only the past two days:
```
journalctl --vacuum-time=2d

```
Retain only the past 500 MB:
```
journalctl --vacuum-size=500M

```


/opt/health/run-once.sh health
vracli service status    #(check services health) 


RESTART 
Stop

1) /opt/scripts/svc-stop.sh
2) sleep 120
3) /opt/scripts/deploy.sh --onlyClean
Start
/opt/scripts/deploy.sh
In one command
/opt/scripts/svc-stop.sh; sleep 120; /opt/scripts/deploy.sh --onlyClean; sleep 60; /opt/scripts/deploy.sh

'/opt/scripts/deploy.sh --shutdown' is the updated command --onlyClean still works but is depreciated. The script already includes svc-stop.sh and a 120 second wait. So svc-stop.sh is not required to be run prior. It would be good if the documentation was updated.

Also you can can also use deploy.sh --quick when you are starting vRA, which skips the 120 second wait time as it is only there to wait for pods to shutdown.


**deletion of a pod**

    kubectl delete pods -n prelude quickstart-ui-app-7b5b6d654d-rn9df
    kubectl delete pods -n prelude --grace-period=0 --force quickstart-ui-app-7b5b6d654d-lpqr5

**Connect to a pod remotely**

    kubectl -n prelude exec -it blueprints-ui-app-849c88547f-lvxpl /bin/bash
    kubectl exec -it postgres-0 -n prelude bash
    kubectl -n prelude exec -it provisioning-service-app-68687f4d67-nbvms /bin/bash
    kubectl -n prelude exec -it cgs-service-56ff5bf86c-kdjww -- openssl s_client -connect marketplace.vmware.com:443 -servername marketplace.vmware.com

```
kubectl exec -it -n prelude vco-app-799586b7b7-2dcpg -c vco-server-app -- /bin/bash
rpm -hiv --nodeps /vco-cfg-cli.rpm
```


**POSTGRES**

    seq 0 2 | xargs -r -n 1 -I {} kubectl -n prelude exec postgres-{} -- chpst -u postgres repmgr node status
    Postgres issue
    if 2 slave nodes cannot be connected to master, this one will be not ready
    kubectl delete pod -n prelude postgres-2
    kubectl delete pod -n prelude -l app=cmx-service-app


Scenario where one node is not SYNC with DB

    postgres-0 -> replica -> working ok
    postgres-1 -> master -> 1 of 2 replica connected to it.
    postgres-2 -> replica -> unable to sync from master since it is too much behind it.

Fix the replica problem by doing the following
a) Take snapshots of the system
b) SSH to the host running postgres-2 replica
c) Raise postgres debug flag: touch /data/db-data/debug
d) Restart postgres-2 replica: kubectl delete pod -n prelude postgres-2
e) Delete db data: rm -rf /data/db-data
f) This will clear the debug flag also so postgres will start normally and sync

the full db data from master

DUMP

    vracli db dump provisioning-db | xz -c > provisioning-db.xz to compress the output

RABBITMQ

    for n in {0,1,2}; do echo node-$n; kubectl -n prelude exec -ti rabbitmq-ha-$n -- rabbitmqctl cluster_status; done

DISK SIZE

    df -h| grep -Evi "docker|kube"

FLANNEL

    kubectl -n kube-system logs -l name=prelude-noop-intnet-ds -c prelude-noop-intnet-netcheck --tail 1500 --since=5m
    kubectl delete pod -n kube-system -l app=flannel

POD LOG in once (change postgres by generic pod name)

    kubectl -n prelude logs -l name=postgres --tail 1500 --since=20m
    kubectl -n prelude logs -f (use tabulation to list the pod names)
    kubectl -n prelude logs provisioning-service-app-57f5d59954-65vbb --since=1h
    equivalent of tailing the logs

kubectl logs --follow tango-vro-gateway-app-664f79fc8f-b7jk2 -n prelude
since vRA 8.3 logs are stored in /services-logs/

CLUSTER

    vracli cluster exec -- bash -c 'current_node; date'
    vracli cluster exec -- bash -c 'current_node;/opt/health/run.sh health '
