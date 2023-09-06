linux-mpls-test
===============

# Abstract

典型的Linuxシステムで、Network Namespaceを使って仮想的なホストを3つ作成しそれらをvethを使って直列に接続し、中央のホストをルータとすることでパケット中継をテストする。

その際、片側のホストとルータの間はMPLSラベルを付与する。LSP等の経路交換プロトコルは用いず、静的に設定する。

# Requirements

 - `iproute2`
 - GNU Make
 - `sudo`

# Topology

```
.-------.               
| HostA |
`-------'         
  veth1   MPLS label 55, 172.21.0.2/24
    |
  veth0   MPLS label 55, 172.21.0.1/24
.-------.
| MPLS  |
`-------'
  veth2   192.168.100.1/24
    |
  veth3   192.168.100.2/24
.-------.
| HostB |
`-------'

```

# Usage

- `make setup` - 仮想ホストを作成し設定する
- `make ping_AtoB` - HostAからHostBにpingする
- `make ping_BtoA` - HostBからHostAにpingする
- `make ping_A` - HostAからMPLSにpingする
- `make ping_B` - HostBからMPLSにpingする
- `make dump_start` - 各vethでのtcpdumpを開始する
- `make dump_stop` - tcpdumpを止める
- `make clean` - 仮想ホストとpcapファイルを消去する

# Tested platforms

- Ubuntu 22.04 LTS

# Description

## Basic setup

### MPLS

```
modprobe mpls_router
sysctl net.mpls.platform_labels=$(MAXLABELS)
```

### receive MPLS packet (pop label)

```
sysctl net.mpls.conf.$(NETDEV).input=1
ip -M route $(LABEL) via inet 127.0.0.1
```

### send MPLS packet (push label)

```
ip route add $(DEST) encap mpls $(LABEL) via $(NEXTHOP)
```
