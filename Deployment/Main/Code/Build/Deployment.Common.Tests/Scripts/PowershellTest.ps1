[cmdletbinding()]
param([string]$Group)

get-verb | ? {$_.Group -eq $Group}
