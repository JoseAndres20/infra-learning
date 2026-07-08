# infra-learning

Laboratorio portable de infraestructura empresarial automatizado con Vagrant. Despliega entornos completos de Active Directory, seguridad web y redes segmentadas con un solo comando.

**Soporte**: Libvirt (KVM) en Linux | VirtualBox (Windows/Linux/macOS)

## Fases del Proyecto

| Fase | Laboratorio | Estado |
|------|-------------|--------|
| 1 | Active Directory y Gestión de Identidades | Activo |
| 2 | Seguridad Web, Proxies y Contenedores | Planeado |
| 3 | Redes, Segmentación y Firewall Perimetral | Planeado |

## Fase 1: Laboratorio de Active Directory

### Arquitectura

```
[Tu PC] --RDP:33890--> [DC-SERVER] (192.168.56.10)
                          | Windows Server 2022
                          | AD DS + DNS + DHCP
                          | Dominio: infra.local
                          |
                       [RED PRIVADA] 192.168.56.0/24
                          |
                       [WIN-CLIENT] (192.168.56.11)
                          | Windows 11 Enterprise
                          | Unido al dominio
```

### Prerrequisitos

**Opción A: Libvirt (KVM) — Linux nativo (recomendado)**
- Vagrant 2.3+ + plugin `vagrant-libvirt`
- KVM/QEMU instalado y funcionando
- Paquete `edk2-ovmf` (UEFI firmware):
  ```bash
  # Fedora
  sudo dnf install -y edk2-ovmf
  # Debian/Ubuntu
  sudo apt install -y ovmf
  ```

**Opción B: VirtualBox**
- [VirtualBox](https://www.virtualbox.org/) 6.1+
- Vagrant 2.3+

### Uso rápido

```bash
cd labs/01-active-directory

# Libvirt (KVM) — Fedora y Linux
export VAGRANT_LIBVIRT_OVMF_CODE=/usr/share/edk2/ovmf/OVMF_CODE.fd
vagrant up --provider=libvirt

# VirtualBox
vagrant up
```

Si la descarga del box falla, agregalo manualmente:
```bash
vagrant box add gusztavvargadr/windows-server-2022-standard
vagrant box add gusztavvargadr/windows-11-25h2-enterprise
```

### Acceso por RDP (interfaz gráfica)

| Máquina | RDP Local | Usuario | Contraseña |
|---------|-----------|---------|------------|
| DC-SERVER | `localhost:33890` | `INFRA\Administrator` | `P@ssw0rd2024!` |
| Win-Client | `localhost:33891` | `INFRA\Administrator` | `P@ssw0rd2024!` |

> **Con Virt-Manager** (Linux/libvirt): Abrí `virt-manager`, conectate a QEMU/KVM, las VMs aparecen como `infra-learning_dc-server` e `infra-learning_win-client`. Usá la opción "Spice" para ver la pantalla.

### Estructura del Dominio

```
infra.local
├── Direccion
│   ├── GG-Direccion
│   ├── Carlos Mendoza (cmendoza)
│   └── Laura Gutierrez (lgutierrez)
├── Tecnologia
│   ├── GG-TI-Admin
│   ├── GG-TI-Soporte
│   ├── Miguel Torres (mtorres) [credenciales en descripcion]
│   ├── Ana Ramirez (aramirez)
│   └── Pedro Sanchez (psanchez)
├── RecursosHumanos
│   ├── GG-RRHH
│   ├── Sofia Martinez (smartinez)
│   └── Jorge Lopez (jlopez)
├── Ventas
│   ├── GG-Ventas
│   ├── Maria Garcia (mgarcia)
│   ├── Luis Hernandez (lhernandez)
│   └── Elena Diaz (ediaz)
├── Servicios
│   ├── GG-Servicios
│   ├── Admin-Service (svc-adm)
│   └── Backup-Service (svc-backup)
└── Privilegiados
```

### Configuraciones débiles (fines educativos)

| Vulnerabilidad | Ubicación | Descripción |
|---------------|-----------|-------------|
| Contraseña en descripción | Usuario `mtorres` | La contraseña está visible en el campo "Descripción" |
| Complejidad baja | GPO: `Politica-Contrasenas-Debil` | Longitud mínima 4, complejidad desactivada |
| Auditoría desactivada | GPO: `Politica-Auditoria-Minima` | No se registran eventos de inicio de sesión |
| SPNs para Kerberoasting | Usuarios `svc-adm`, `svc-backup` | Cuentas de servicio (configurable) |
| Sin bloqueo de cuenta | Política por defecto | No hay bloqueo tras intentos fallidos |

### Scripts de aprovisionamiento

| Script | Ejecución | Función |
|--------|-----------|---------|
| `scripts/setup-dc.ps1` | 1ra (DC) | IP fija, instala AD DS, crea bosque `infra.local` |
| `scripts/create-users.ps1` | 2da (DC) | DHCP, OUs, grupos, 12 usuarios, GPOs débiles |
| `scripts/enable-rdp-gui.ps1` | 3ra (DC) | Habilita RDP, firewall, accesos directos GUI |
| `scripts/join-client.ps1` | 1ra (Cliente) | Configura DNS, espera al DC, une al dominio |

### Red privada

- **Subred**: `192.168.56.0/24`
- **DC-SERVER**: `192.168.56.10` (fija)
- **WIN-CLIENT**: `192.168.56.11` (fija)
- **DHCP**: `192.168.56.20` - `192.168.56.200` (futuros dispositivos)
- **DNS**: `192.168.56.10`

### Nota sobre reinicios

El script `setup-dc.ps1` crea el bosque de Active Directory, lo que provoca un reinicio automático. Vagrant detectará la desconexión y se reconectará para ejecutar los scripts posteriores. Si la provisión se detiene tras el reinicio:

```bash
vagrant provision dc-server
```

El cliente también se reinicia al unirse al dominio (`join-client.ps1`). Vagrant lo maneja automáticamente.

### Próximos laboratorios

- **Fase 2**: Laboratorio de Seguridad Web (DVWA, OWASP Juice Shop, WAF con ModSecurity)
- **Fase 3**: Laboratorio de Redes (pfSense, DMZ, VPN)
