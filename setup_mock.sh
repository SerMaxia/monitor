#!/bin/bash
mkdir -p /var/log/monitoring-lab/data
mkdir -p /var/log/monitoring-lab/tmp/tree

cat << 'EOF' > /var/log/monitoring-lab/data/app.log
192.168.1.1 GET / ERROR
192.168.1.2 GET / CRITICAL
192.168.1.3 GET / SECRET=12345
EOF

cat << 'EOF' > /var/log/monitoring-lab/data/metrics.csv
id,host,cpu_pct,mem
1,server1,96,20
2,server2,50,20
3,server3,99,20
4,server4,10,20
5,server5,10,20
6,server6,10,20
7,server7,10,20
EOF

touch /var/log/monitoring-lab/tmp/tree/test.bak
echo "SECRET=abcd" > /var/log/monitoring-lab/tmp/tree/secret.txt
