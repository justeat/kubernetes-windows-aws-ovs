param(
[string] $K8S_PATH="C:\kubernetes",
[string] $K8S_VERSION="${k8s_version}",
[string] $KUBERNETES_API_SERVER = "${k8s_api_service_ip}",
[string] $K8S_DNS_SERVICE_IP  = "${k8s_dns_service_ip}",
[string] $K8S_DNS_DOMAIN = "${k8s_dns_domain}"
)
# 

#$HOSTNAME = hostname
$HOSTNAME = [IO.File]::ReadAllText("c:\hostname").replace("`n","").replace("`r","")
write-host "HOSTNAME: $HOSTNAME"

write-host "install_k8s.ps1 -K8S_PATH '$K8S_PATH' -K8S_VERSION '$K8S_VERSION' -KUBERNETES_API_SERVER '$KUBERNETES_API_SERVER' -K8S_DNS_SERVICE_IP  '$K8S_DNS_SERVICE_IP' -K8S_DNS_DOMAIN '$K8S_DNS_DOMAIN' "

mkdir $K8S_PATH
cd $K8S_PATH

# Download and extract Kubernetes binaries
$start_time = Get-Date
$uri = "https://dl.k8s.io/v" + $K8S_VERSION + "/kubernetes-node-windows-amd64.tar.gz"
$out = $K8S_PATH + "\kubernetes-node-windows-amd64.tar.gz"
write-host $uri
write-host $out
Invoke-WebRequest -Uri $uri -OutFile $out

write-host  "openvswitch-hyperv-2.7.0-certified.msi Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

cmd /c '"C:\Program Files\7-Zip\7z.exe" e kubernetes-node-windows-amd64.tar.gz'
cmd /c '"C:\Program Files\7-Zip\7z.exe" x kubernetes-node-windows-amd64.tar'
mv kubernetes\node\bin\*.exe .
Remove-Item -Recurse -Force kubernetes
Remove-Item -Recurse -Force kubernetes-node-windows-amd64*

$cmd = 'sc create kubelet binPath= "\"c:\Program Files\Cloudbase Solutions\Open vSwitch\bin\servicewrapper.exe\" kubelet \"C:\kubernetes\kubelet.exe\" -v=3 --hostname-override={0} --cluster-dns={1} --cluster-domain={2} --pod-infra-container-image=\"apprenda/pause\" --resolv-conf=\"\" --api_servers=\"http://{3}:8080\" --logtostderr=false  --cloud-provider=aws  --log-dir=\"C:\kubernetes\"" type= own start= auto error= ignore displayname= "Kubernetes Kubelet" obj= LocalSystem' -f $HOSTNAME, $K8S_DNS_SERVICE_IP, $K8S_DNS_DOMAIN, $KUBERNETES_API_SERVER
cmd /c $cmd

#We are going to reboot so kubelet will start then.
#Start-Service kubelet