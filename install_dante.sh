#!/bin/bash

# Проверка серверов на пинг
all_error=true
i=1
for ip in 185.169.134.139 185.169.134.140 80.66.71.76 80.66.71.77 185.169.134.35 185.169.134.36 80.66.71.74 80.66.71.75 185.169.134.123 185.169.134.124 80.66.71.80 80.66.71.81 80.66.71.78 80.66.71.79 80.66.71.82 80.66.71.83 80.66.71.84 80.66.71.61 80.66.71.71 80.66.71.91 80.66.71.92; do
  num=$(printf "%02d" $i)
  if ping -c 1 -W 1 $ip >/dev/null; then
    echo -e "\e[38;5;44m[$num] $ip\t\e[32myes\e[0m"
    all_error=false
  else
    echo -e "\e[38;5;44m[$num] $ip\t\e[31merror\e[0m"
  fi
  ((i++))
done

# Если все IP недоступны — завершить выполнение скрипта
#if [ "$all_error" = true ]; then
#  echo -e "\e[31mВсе проверочные сервера недоступны, установка Dante прервана.\e[0m"
#  exit 1
#fi

# Установка Dante
apt install dante-server -y

# Создание пользователя
useradd -m radmir
echo "radmir:proxy" | chpasswd

# Обнуление и заполнение конфигурационного файла
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

# Перезапуск Dante
systemctl restart danted

# Добавление задержки перед запуском при старте системы
mkdir -p /etc/systemd/system/danted.service.d
cat > /etc/systemd/system/danted.service.d/override.conf <<EOF
[Service]
ExecStartPre=/bin/sleep 15
EOF

systemctl daemon-reload
systemctl enable danted

# Проверка статуса службы
systemctl status danted --no-pager

# Вывод итоговой информации
IP=$(hostname -I | awk '{print $1}')
echo -e "\e[32m$IP:1080 radmir proxy RP_00 1\e[0m"
