$ErrorActionPreference = "Stop"
Start-Transcript -Path "C:\setup-dc.log" -Append

# ──────────────────────────────────────────────
# 1. IDENTIFICAR INTERFAZ PRIVADA (infra-net)
# ──────────────────────────────────────────────
Write-Output "[1/5] Identificando interfaz de red privada..."

$existingIP = Get-NetIPAddress -IPAddress "192.168.56.*" -ErrorAction SilentlyContinue
if ($existingIP) {
    $adapter = Get-NetAdapter -InterfaceIndex $existingIP.InterfaceIndex
    Write-Output "  Interfaz encontrada: $($adapter.Name) (ifIndex: $($adapter.ifIndex))"
} else {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    $adapter = $adapters | Select-Object -Last 1
    Write-Output "  Usando ultima interfaz disponible: $($adapter.Name)"
}

# ──────────────────────────────────────────────
# 2. CONFIGURAR IP FIJA 192.168.56.10/24
# ──────────────────────────────────────────────
Write-Output "[2/5] Configurando IP fija 192.168.56.10/24..."

Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

New-NetIPAddress -InterfaceIndex $adapter.ifIndex `
    -IPAddress "192.168.56.10" `
    -PrefixLength 24 `
    -DefaultGateway "192.168.56.1" `
    -ErrorAction Stop | Out-Null

Write-Output "  IP  : 192.168.56.10/24"
Write-Output "  GW  : 192.168.56.1"

# ──────────────────────────────────────────────
# 3. CONFIGURAR DNS → loopback (para AD)
# ──────────────────────────────────────────────
Write-Output "[3/5] Configurando DNS (127.0.0.1)..."
Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses "127.0.0.1"
Write-Output "  OK"

# ──────────────────────────────────────────────
# 4. HABILITAR RDP
# ──────────────────────────────────────────────
Write-Output "[4/5] Habilitando RDP + firewall..."
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Write-Output "  RDP listo en localhost:33890"

# ──────────────────────────────────────────────
# 5. INSTALAR AD DOMAIN SERVICES
# ──────────────────────────────────────────────
Write-Output "[5/5] Instalando Active Directory Domain Services..."
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools | Out-Null

Write-Output ""
Write-Output "═══════════════════════════════════════════"
Write-Output "  AD DS instalado correctamente."
Write-Output "  Conectate por RDP y crea el dominio"
Write-Output "  desde Server Manager > Add Roles >"
Write-Output "  Promote this server to a domain controller"
Write-Output "═══════════════════════════════════════════"

Stop-Transcript