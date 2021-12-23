#!/bin/bash

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

# installing spawn-fcgi
yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd mc -y

sudo sed -i s/#SOCKET/SOCKET/ /etc/sysconfig/spawn-fcgi
sudo sed -i s/#OPTIONS/OPTIONS/ /etc/sysconfig/spawn-fcgi

#creating spawn-fcgi service unit
cat <<'EOF' | sudo tee /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by OtusLAP
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

#creating httpd template multyinstance file
cat <<'EOF' | sudo tee /usr/lib/systemd/system/httpd@.service
[Unit]
Description=The Apach HTTP Server multyinstance template
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%i 
# %i above is multyinstance parameter

ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
KillSignal=SIGCOUNT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

#creating config files for different instances
touch /etc/httpd/conf/first.conf
sed -n '1,41p' /etc/httpd/conf/httpd.conf >> /etc/httpd/conf/first.conf

echo 'ServerName local_server' >> /etc/httpd/conf/first.conf
echo 'PidFile /var/run/httpd-first.pid' >> /etc/httpd/conf/first.conf
echo 'Listen 10.0.1.127:8081' >> /etc/httpd/conf/first.conf

sed -n '44,354p' /etc/httpd/conf/httpd.conf >> /etc/httpd/conf/first.conf

touch /etc/httpd/conf/second.conf
sed -n '1,41p' /etc/httpd/conf/httpd.conf >> /etc/httpd/conf/second.conf

echo 'ServerName local_server' >> /etc/httpd/conf/second.conf
echo 'PidFile /var/run/httpd-second.pid' >> /etc/httpd/conf/second.conf
echo 'Listen 10.0.1.127:8082' >> /etc/httpd/conf/second.conf

sed -n '44,354p' /etc/httpd/conf/httpd.conf >> /etc/httpd/conf/second.conf

#creating EnvironmentFiles for different instances
touch /etc/sysconfig/httpd-first
echo 'OPTIONS=-f conf/first.conf' >> /etc/sysconfig/httpd-first
touch /etc/sysconfig/httpd-second
echo 'OPTIONS=-f conf/second.conf' >> /etc/sysconfig/httpd-second


# starting services seeking ALERT in /var/log/watchlog.log
systemctl daemon-reload
systemctl enable watchlog.service
systemctl enable watchlog.timer
systemctl start watchlog.service
systemctl start watchlog.timer

#starting spawn-fcgi

systemctl start spawn-fcgi
systemctl status spawn-fcgi

#starting dual instance Apache http Server
setenforce 0
systemctl start httpd@first
systemctl start httpd@second





