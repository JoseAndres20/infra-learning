# Uso del Laboratorio Active Directory

## Requisitos

- **SO**: Fedora Linux (u otra distro con KVM/libvirt)
- **RAM**: 10 GB libres (4 GB DC + 4 GB cliente + 2 GB sistema)
- **Disco**: 130 GB libres por VM (~260 GB total)

---

## Instalación inicial (solo primera vez)

```bash
git clone <repo-url>
cd labs/01-active-directory
./bootstrap.sh
```

El script `bootstrap.sh` instala Vagrant, libvirt, OVMF, TPM, gemas WinRM,
la red `infra-net` y descarga las boxes de Windows.

> **Importante**: después del bootstrap, **cerrar sesión y volver a entrar**
> para que el grupo `libvirt` tenga efecto.

---

## Comandos diarios

### Levantar todo (DC + Cliente)

```bash
vagrant up
```

### Levantar solo una máquina

```bash
vagrant up dc-server      # solo el controlador de dominio
vagrant up win-client     # solo el cliente Windows 11
```

### Apagar (guardando estado)

```bash
vagrant halt              # apaga ambas
vagrant halt dc-server    # apaga solo el DC
vagrant halt win-client   # apaga solo el cliente
```

> `halt` guarda el disco. Al hacer `vagrant up` de nuevo, todo vuelve
> como estaba (AD, usuarios, configuraciones).

### Reaplicar scripts de provisioning

```bash
vagrant provision dc-server
vagrant provision win-client
```

### Destruir (borra discos y configuraciones)

```bash
vagrant destroy           # borra ambas VMs
vagrant destroy -f        # borra sin preguntar
```

> **Cuidado**: `destroy` elimina todo. Usar solo si querés empezar de cero.

---

## Puertos RDP

| Máquina     | Puerto host  | Conexión                        |
|-------------|--------------|---------------------------------|
| DC Server   | `localhost:33890` | `xfreerdp /v:localhost:33890 /u:vagrant /p:vagrant` |
| Win-Client  | `localhost:53390` | `xfreerdp /v:localhost:53390 /u:vagrant /p:vagrant` |

---

## Redes

| Red            | Subred            | Uso                    |
|----------------|-------------------|------------------------|
| vagrant-libvirt| 192.168.121.0/24  | Gestión (WinRM, NAT)  |
| infra-net      | 192.168.56.0/24   | Privada del dominio   |

- **DC**: `192.168.56.10` (fija)
- **Cliente**: DHCP desde `192.168.56.11`
- **Gateway**: `192.168.56.1`

---

## Flujo de trabajo recomendado

```
1. vagrant up           ← levantar todo
2. vagrant halt         ← apagar al terminar
3. vagrant up           ← al día siguiente, levantar de nuevo
4. vagrant destroy      ← solo si querés borrar el laboratorio
```

> `halt` + `up` preserva todo. Solo usar `destroy` cuando ya no necesites el lab.