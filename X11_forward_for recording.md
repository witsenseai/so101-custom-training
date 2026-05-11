# X11 Forwarding: Orin → Windows over LAN

## Setup
- Windows and Orin connected via LAN cable
- Windows: `192.168.10.2` (Ethernet adapter)
- Orin: `192.168.10.3` (interface `enP8p1s0`)
- XServer on Windows: VcXsrv

---

## Windows

**1. Start VcXsrv (disable access control)**
```cmd
"C:\Program Files\VcXsrv\vcxsrv.exe" :0 -multiwindow -ac -listen tcp -nowgl
```

**2. Allow port 6000 through firewall (PowerShell as Admin)**
```powershell
New-NetFirewallRule -DisplayName "XLaunch X11" -Direction Inbound -Protocol TCP -LocalPort 6000 -Action Allow
```

**3. Verify listening**
```cmd
netstat -an | findstr 6000
# Expected: TCP  0.0.0.0:6000  LISTENING
```

---

## Orin

**1. Assign IP to LAN interface**
```bash
sudo ip addr add 192.168.10.3/24 dev enP8p1s0
```

**2. Set DISPLAY**
```bash
export DISPLAY=192.168.10.2:0.0
```

**3. Test**
```bash
xeyes   # sudo apt install x11-apps if missing
```

**4. Make permanent**
```bash
echo 'export DISPLAY=192.168.10.2:0.0' >> ~/.bashrc
```

> Note: `sudo ip addr add` does not survive reboot. To persist, configure via `/etc/netplan/`.