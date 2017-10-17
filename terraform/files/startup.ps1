$services = "ovn-controller"
$maxRepeat = 60
$status = "Running" # change to Stopped if you want to wait for services to start
do 
{
    $count = (Get-Service $services | ? {$_.status -ne $status}).count
    $maxRepeat--
    sleep 1
} until ($count -eq 0 -or $maxRepeat -eq 0)

& ovs-ofctl  add-flow br-ex priority=1,action=strip_vlan,NORMAL

$x = Get-NetIPConfiguration | Foreach IPv4DefaultGateway
$dgw = $x.NextHop
& route ADD 169.254.169.250 MASK 255.255.255.255 "$dgw" METRIC 50
& route ADD 169.254.169.251 MASK 255.255.255.255 "$dgw" METRIC 50
& route ADD 169.254.169.254 MASK 255.255.255.255 "$dgw" METRIC 50

start-service "kubelet"