[How-to-get-tcpdump-for-containers-inside-Kubernetes-pods](https://community.pivotal.io/s/article/How-to-get-tcpdump-for-containers-inside-Kubernetes-pods?language=en_US)

abx: 
```
export abxpod=`kubectl -n openfaas-fn get pods | grep abx | awk {'print $1'}` 
kubectl -n openfaas-fn get pod $abxpod -o json | grep -E 'containerID|hostIP'
export containerid=`kubectl -n openfaas-fn get pod $abxpod -o json | grep containerID | awk -F ':' {'print $3'} | cut -b 3-66` 
export iplink=`docker exec $containerid /bin/bash -c 'cat /sys/class/net/eth0/iflink'`
export interface=`ip link |grep ^$iplink` 
export tcpint=`echo $interface | cut -b 6-17` 
tcpdump -i $tcpint -w abx-capture.pcap tcp port 3128
```

Proxy:
```
export proxypod=`kubectl -n prelude get pods | grep proxy | awk {'print $1'}` 
kubectl -n prelude get pod $proxypod -o json | grep -E 'containerID|hostIP'
export proxycontainerid=`kubectl -n prelude get pod $proxypod -o json | grep containerID | awk -F ':' {'print $3'} | cut -b 3-66` 
export proxyiplink=`docker exec $proxycontainerid /bin/bash -c 'cat /sys/class/net/eth0/iflink'`
export proxyinterface=`ip link |grep ^$proxyiplink` 
export proxytcpint=`echo $proxyinterface | cut -b 5-16` 
tcpdump -i $proxytcpint -w proxy-capture.pcap
```

export vcopod=`docker ps | grep k8s_vco-server-app | awk {'print $1'}`
docker exec $vcopod /bin/bash -c 'cat /sys/class/net/eth0/iflink'
ip link |grep ^100
pdump -i veth -w proxy-capture.pcap

