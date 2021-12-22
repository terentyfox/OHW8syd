#!/bin/bash
yum install -y epel-release
#creating ExecStart script
cat <<'EOF' | sudo tee /opt/watchlog.sh
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &>/dev/null
then
    logger "$DATE: I found word, Master!"
else
    exit 0
fi
EOF

#creating file to monitor
cat <<'EOF' | sudo tee /var/log/watchlog.log
string 1
string 2
ALERT
other strings
EOF

# creating config file 
cat <<'EOF' | sudo tee /etc/sysconfig/watchlog
#Word to seek
WORD='ALERT'

#File to monitor
LOG=/var/log/watchlog.log
EOF

# creating service unit
cat <<'EOF' | sudo tee /lib/systemd/system/watchlog.service
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/bin/bash /opt/watchlog.sh $WORD $LOG
EOF

#creating timer unit
cat <<'EOF' | sudo tee /lib/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every half a minute
[Timer]
OnUnitActiveSec=30s
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
EOF


