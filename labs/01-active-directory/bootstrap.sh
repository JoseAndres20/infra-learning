#!/bin/bash
set -euo pipefail

echo "=== [1/6] Instalando dependencias del sistema ==="
sudo dnf install -y \
    @virtualization \
    vagrant vagrant-libvirt \
    edk2-ovmf swtpm

echo "=== [2/6] Habilitando libvirtd ==="
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt "$USER"

echo "=== [3/6] Instalando gemas WinRM ==="
vagrant plugin install winrm winrm-elevated winrm-fs 2>/dev/null || {
    # fallback si vagrant plugin install falla
    vagrant winrm -v 2>/dev/null || {
        user_gems=$(ruby -e 'puts Gem.user_dir')
        gem install --user winrm winrm-elevated winrm-fs -v "~> 2.0" 2>/dev/null
        wd="$HOME/.vagrant.d/gems/4.0.5"
        mkdir -p "$wd"
        cp -r "$user_gems/gems/winrm-"* "$wd/" 2>/dev/null || true
        # deshabilitar conflicto rubyzip si existe
        sudo mv /usr/share/gems/specifications/rubyzip-3.2.2.gemspec{,.disabled} 2>/dev/null || true
    }
}

echo "=== [4/6] Creando red privada infra-net ==="
sudo virsh net-destroy infra-net 2>/dev/null || true
sudo virsh net-undefine infra-net 2>/dev/null || true

cat <<'NETEOF' | sudo virsh net-define /dev/stdin
<network connections='1'>
  <name>infra-net</name>
  <forward mode='nat'>
    <nat><port start='1024' end='65535'/></nat>
  </forward>
  <bridge name='virbr1' stp='on' delay='0'/>
  <ip address='192.168.56.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.56.11' end='192.168.56.254'/>
    </dhcp>
  </ip>
</network>
NETEOF

sudo virsh net-start infra-net
sudo virsh net-autostart infra-net
echo "  Red infra-net (192.168.56.0/24) lista"

echo "=== [5/6] Agregando boxes ==="
vagrant box add gusztavvargadr/windows-server-2022-standard --provider=libvirt 2>/dev/null || true
vagrant box add gusztavvargadr/windows-11-25h2-enterprise --provider=libvirt 2>/dev/null || true

echo "=== [6/6] Setup completo ==="
echo ""
cd "$(dirname "$0")"
echo "Cierra sesion y vuelve a entrar para que el grupo libvirt tenga efecto."
echo "Despues ejecuta: cd $(pwd) && vagrant up"