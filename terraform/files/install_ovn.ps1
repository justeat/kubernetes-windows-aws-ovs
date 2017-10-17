
param(
[string] $SUBNET="10.244.9.0/24",
[string] $GATEWAY_IP="10.244.9.1", # first ip of the subnet
[string] $CLUSTER_IP_SUBNET="10.244.0.0/16", # The big subnet which includes the minions subnets
[string] $INTERFACE_ALIAS="Ethernet", # Interface used for creating the overlay tunnels (must have connectivity with other hosts)
[string] $KUBERNETES_API_SERVER="10.142.0.2", # API kubernetes server IP
[string] $INTERFACE_NAME="Ethernet",
[string] $PUBLIC_IP=(Get-NetIPConfiguration | Where-Object {$_.InterfaceAlias -eq "$INTERFACE_NAME"}).IPv4Address.IPAddress
)

$a,$b,$c,$d = $PUBLIC_IP.split(".");
$region =  "eu-west-1"
$HOSTNAME = "ip-$a-$b-$c-$d.$region.compute.internal"

Add-content "C:\hostname" -value $HOSTNAME

write-host "install_ovn.ps1 -SUBNET '$SUBNET' -GATEWAY_IP '$GATEWAY_IP' -CLUSTER_IP_SUBNET '$CLUSTER_IP_SUBNET' -INTERFACE_ALIAS '$INTERFACE_ALIAS'  -KUBERNETES_API_SERVER '$KUBERNETES_API_SERVER' -INTERFACE_NAME '$INTERFACE_NAME' -PUBLIC_IP='$PUBLIC_IP'" 
#$HOSTNAME=hostname
$K8S_ZIP=".\k8s_ovn_service_prerelease.zip" # Location of k8s OVN binaries (DO NOT CHANGE unless you know what you're doing)
$OVS_PATH="c:\Program Files\Cloudbase Solutions\Open vSwitch\bin" # Default installation directory for OVS (DO NOT CHANGE unless you know what you're doing)
write-host "HOSTNAME: $HOSTNAME "

$env:path = $env:path + ";c:\Program Files\Cloudbase Solutions\Open vSwitch\bin;c:\kubernetes;C:\Program Files\Amazon\AWSCLI"

#write-host "sleeping for 120 to see if waiting helps"
#sleep 120
write-host "finsihed sleeping"
write-host "$env:path"
write-host 

#exit 1

Stop-Service docker
Get-ContainerNetwork | Remove-ContainerNetwork -Force
cmd /c 'echo { "bridge" : "none" } > C:\ProgramData\docker\config\daemon.json'
Start-Service docker

docker network create -d transparent --gateway $GATEWAY_IP --subnet $SUBNET -o com.docker.network.windowsshim.interface=$INTERFACE_ALIAS external

$a = Get-NetAdapter | where Name -Match HNSTransparent
rename-netadapter $a[0].name -newname HNSTransparent

$DB_SOCK="--db=unix:c:/ProgramData/openvswitch/run/openvswitch/db.sock"

stop-service ovs-vswitchd -force; disable-vmswitchextension "cloudbase open vswitch extension";
write-host "del br"
ovs-vsctl $DB_SOCK --no-wait del-br br-ex
write-host "add br ex"
ovs-vsctl $DB_SOCK --no-wait --may-exist add-br br-ex
write-host "add port br-ex HNSTransparent"
ovs-vsctl $DB_SOCK --no-wait add-port br-ex HNSTransparent -- set interface HNSTransparent type=internal
write-host "add-port br-ex $INTERFACE_ALIAS "
ovs-vsctl $DB_SOCK --no-wait add-port br-ex $INTERFACE_ALIAS

enable-vmswitchextension "cloudbase open vswitch extension"; sleep 2; restart-service ovs-vswitchd

sleep 5 
write-host "setting up open v switch"

ovs-vsctl $DB_SOCK set Open_vSwitch . external_ids:k8s-api-server="$($KUBERNETES_API_SERVER):8080"
ovs-vsctl $DB_SOCK set Open_vSwitch . external_ids:ovn-remote="tcp:$($KUBERNETES_API_SERVER):6642" external_ids:ovn-nb="tcp:$($KUBERNETES_API_SERVER):6641" external_ids:ovn-encap-ip=$PUBLIC_IP external_ids:ovn-encap-type="geneve"

$GUID = (New-Guid).Guid
ovs-vsctl $DB_SOCK set Open_vSwitch . external_ids:system-id="$($GUID)"
ovs-ofctl  add-flow br-ex priority=1,action=strip_vlan,NORMAL
sleep 5
write-host "debugging data:" 

ovs-vsctl $DB_SOCK get Open_vSwitch . external_ids
ovs-vsctl $DB_SOCK show 

sleep 5

# On some cloud-providers this is needed, otherwise RDP connection may bork
netsh interface ipv4 set subinterface "HNSTransparent" mtu=1430 store=persistent

$unzipCmd = '"C:\Program Files\7-Zip\7z.exe" e -aos "{0}" -o"{1}" -x!*libeay32.dll -x!*ssleay32.dll'  -f $K8S_ZIP, $OVS_PATH
cmd /c $unzipCmd

cmd /c 'sc create ovn-k8s binPath= "\"c:\Program Files\Cloudbase Solutions\Open vSwitch\bin\servicewrapper.exe\" ovn-k8s \"c:\Program Files\Cloudbase Solutions\Open vSwitch\bin\k8s_ovn.exe\"" type= own start= auto error= ignore depend= ovsdb-server/ovn-controller displayname= "OVN Watcher" obj= LocalSystem'

sleep 5
write-host "adding aws strip vlan setting"
ovs-ofctl  add-flow br-ex priority=1,action=strip_vlan,NORMAL
write-host "strip vlan done "
write-host "running windows-init  $HOSTNAME $SUBNET $CLUSTER_IP_SUBNET"
sleep 5
windows-init.exe windows-init --node-name $HOSTNAME --minion-switch-subnet $SUBNET --cluster-ip-subnet $CLUSTER_IP_SUBNET

sleep 5

start-service ovn-k8s
