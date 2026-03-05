#!/bin/bash
apt update -y
apt install dante-server -y

useradd -m radmir
echo "radmir:proxy" | chpasswd

truncate -s 0 /etc/danted.conf

cat > /etc/danted.conf <<EOF
logoutput: syslog
internal: eth0 port = 1080
external: eth0
socksmethod: username
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
}

socks block {
    from: 0.0.0.0/0 to: 127.0.0.0/8
    log: connect error
}

socks block {
    from: 0.0.0.0/0 to: 10.0.0.0/8
    log: connect error
}

socks block {
    from: 0.0.0.0/0 to: 192.168.0.0/16
    log: connect error
}

socks block {
    from: 0.0.0.0/0 to: 172.16.0.0/12
    log: connect error
}
EOF

systemctl restart danted

mkdir -p /etc/systemd/system/danted.service.d
cat > /etc/systemd/system/danted.service.d/override.conf <<EOF
[Service]
ExecStartPre=/bin/sleep 15
EOF

systemctl daemon-reload
systemctl enable danted

IP=$(hostname -I | awk '{print $1}')
echo "$IP:1080 radmir proxy RP_00 1"
