<powershell>
$ZONE_NAME = "itrunner.org"

$prod_app1_ip = "10.184.12.188"

function UpdateDnsIP($HostName,$IP) {
  $OldObj = Get-DnsServerResourceRecord -Name $HostName -ZoneName $ZONE_NAME -RRType "A"
  $NewObj = $OldObj.Clone()
  $NewObj.RecordData.IPv4address = [System.Net.IPAddress]::parse($IP)
  Set-DnsServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $ZONE_NAME -PassThru
}

function UpdateDnsCName($HostName,$HostNameAlias) {
  $OldObj = Get-DnsServerResourceRecord -Name $HostName -ZoneName $ZONE_NAME -RRType "CName"
  $NewObj = $OldObj.Clone()
  $NewObj.RecordData.HostNameAlias = $HostNameAlias
  Set-DnsServerResourceRecord -NewInputObject $NewObj -OldInputObject $OldObj -ZoneName $ZONE_NAME -PassThru
}

function UpdateDns {
  UpdateDnsIP prod-app1 $prod_app1_ip
}

UpdateDns
</powershell>
