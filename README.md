# AntiDDos
Примитивная защита от DDoS

# Установка
Требуется установить ipset и добавить таблицы:
```
ipset create ban6 hash:ip family inet6 hashsize 4096 maxelem 65536 timeout 300
ipset create ban61 hash:ip family inet6 hashsize 4096 maxelem 65536 timeout 1800
ipset create ban62 hash:ip family inet6 hashsize 4096 maxelem 65536 timeout 6000
ipset create ban63 hash:ip family inet6 hashsize 4096 maxelem 65536 timeout 12000

ipset create ban hash:ip family inet hashsize 4096 maxelem 65536 timeout 300
ipset create ban1 hash:ip family inet hashsize 4096 maxelem 65536 timeout 1800
ipset create ban2 hash:ip family inet hashsize 4096 maxelem 65536 timeout 6000
ipset create ban3 hash:ip family inet hashsize 4096 maxelem 65536 timeout 12000
```
Добавить в iptables правила (номер линии задайте после правила довернных IP)
```
ip6tables -I INPUT 3 -m set --match-set ban6 src -j DROP
ip6tables -I INPUT 4 -m set --match-set ban61 src -j DROP
ip6tables -I INPUT 5 -m set --match-set ban62 src -j DROP
ip6tables -I INPUT 6 -m set --match-set ban63 src -j DROP

iptables -I INPUT 3 -m set --match-set ban src -j DROP
iptables -I INPUT 4 -m set --match-set ban1 src -j DROP
iptables -I INPUT 5 -m set --match-set ban2 src -j DROP
iptables -I INPUT 6 -m set --match-set ban3 src -j DROP
```

Вешаем на крон:
```
*/2 * * * * root sh путь/antiddos.sh путь domain.com 60
```
Где
-путь: это в коде $1 (требуется для пути к логам конкретного сайта)
-domain.com: это в коде $2 (требуется для пути к логам конкретного сайта)
-60: максимальное лисло запросов с одного 1 ip в минуту.
