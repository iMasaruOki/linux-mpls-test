IPNETNS=sudo ip netns
LABEL=55

setup: make_netns make_veth bind_veth assign_ip setup_mpls setup_router setup_route

ping:
	${IPNETNS} exec HostB ping 172.21.0.2

ping_A:
	${IPNETNS} exec HostA ping 172.21.0.1

ping_AtoB:
	${IPNETNS} exec HostA ping 192.168.100.2

ping_B:
	${IPNETNS} exec HostB ping 192.168.100.1

ping_BtoA:
	${IPNETNS} exec HostB ping 172.21.0.2

show:
	for ns in MPLS HostA HostB; do \
		echo =========================; \
		echo $$ns; \
		for cmd in route "-M route" addr; do \
		  echo "##### ip" $$cmd; \
		  ${IPNETNS} exec $$ns ip $$cmd; \
		done; \
	done

dump_start:
	for ns in MPLS HostA HostB; do \
		for veth in $$(${IPNETNS} exec $$ns ls /proc/sys/net/ipv4/conf|grep veth); do \
			${IPNETNS} exec $$ns /bin/sh -c "tcpdump -w $$ns-$$veth.pcap -i $$veth &" ; \
		done; \
	done
dump_stop:
	for ns in MPLS HostA HostB; do \
		${IPNETNS} exec $$ns pkill tcpdump; \
	done

clean:
	rm -f *.pcap
	${IPNETNS} del HostA
	${IPNETNS} del HostB
	${IPNETNS} del MPLS

make_netns:
	${IPNETNS} add HostA
	${IPNETNS} add HostB
	${IPNETNS} add MPLS

make_veth:
	sudo ip link add type veth
	sudo ip link add type veth

bind_veth:
	${IPNETNS} exec MPLS ip link set lo up
	${IPNETNS} exec HostA ip link set lo up
	${IPNETNS} exec HostB ip link set lo up
	sudo ip link set veth0 netns MPLS up
	sudo ip link set veth1 netns HostA up
	sudo ip link set veth2 netns MPLS up
	sudo ip link set veth3 netns HostB up

assign_ip:
	${IPNETNS} exec MPLS ip addr add 172.21.0.1/24 dev veth0
	${IPNETNS} exec HostA ip addr add 172.21.0.2/24 dev veth1
	${IPNETNS} exec MPLS ip addr add 192.168.100.1/24 dev veth2
	${IPNETNS} exec HostB ip addr add 192.168.100.2/24 dev veth3

setup_mpls:
	sudo modprobe mpls_router
	${IPNETNS} exec MPLS sysctl net.mpls.platform_labels=64
	${IPNETNS} exec MPLS sysctl net.mpls.conf.veth0.input=1
	${IPNETNS} exec HostA sysctl net.mpls.platform_labels=64
	${IPNETNS} exec HostA sysctl net.mpls.conf.veth1.input=1

setup_router:
	${IPNETNS} exec MPLS sysctl net.ipv4.conf.all.forwarding=1

setup_route:
	${IPNETNS} exec MPLS ip -M route add ${LABEL} dev lo
	${IPNETNS} exec MPLS ip route add 172.21.0.2/32 encap mpls ${LABEL} via inet 172.21.0.2
	${IPNETNS} exec HostA ip -M route add ${LABEL} dev lo
	${IPNETNS} exec HostA ip route add 192.168.100.0/24 encap mpls ${LABEL} via 172.21.0.1
	${IPNETNS} exec HostB ip route add 172.21.0.0/24 via 192.168.100.1
