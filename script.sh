#!/bin/bash
yum -y update
sleep 1
yum install make wget gcc pcre-static pcre-devel
wget http://haproxy.1wt.eu/download/1.5/src/devel/haproxy-1.5-dev7.tar.gz
tar -zxf haproxy-1.5-dev7.tar.gz
cd haproxy-1.5-dev7
make TARGET=linux26 USE_STATIC_PCRE=1 USE_LINUX_TPROXY=1
cp haproxy /usr/sbin/haproxy
echo 'HAproxy installation complete'

cat >> /etc/sysctl.conf << SYSCTLEDIT
net.ipv4.ip_nonlocal_bind = 1
SYSCTLEDIT
sysctl -p /etc/sysctl.conf
sleep 1

echo 'Installing epel repo end heartbeat'
mkdir /download
cd download/
wget ftp://mirror.switch.ch/pool/1/mirror/scientificlinux/6rolling/i386/os/Packages/epel-release-6-5.noarch.rpm
rpm -ivUh epel-release-6-5.noarch.rpm
echo 'Summon enabled=0 on line 6'
vi /etc/yum.repos.d/epel.repo
readOne () {
tput smso
echo "Press any key to return \c"
tput rmso
oldstty=`stty -g`
stty -icanon -echo min 1 time 0
dd bs=1 count=1 >/dev/null 2>&1
stty "$oldstty"
echo
}
yum --enablerepo=epel install heartbeat

touch /etc/haproxy.cfg
touch /etc/ha.d/haresources
touch /etc/ha.d/authkeys
touch /etc/ha.d/ha.cf
echo "auth 2" >> authkeys
echo "2 sha1 `< /dev/urandom tr -dc A-Za-z0-9_ | head -c24`" >> authkeys
chmod 600 /etc/ha.d/authkeys*

cat > /etc/haproxy.cfg.example << HAPROXYEX
global
   log         127.0.0.1 local0
   log         127.0.0.1 local1 notice
   #log        loghost local0 info
   daemon
   nbproc      1 # Number of processing cores/cpus.
   #user       nobody
   #group      nobody

frontend ft_smtp
  bind 192.168.126.145:25
  mode tcp
  no option http-server-close
  timeout client 1m
  log global
  option tcplog
  default_backend bk_postfix
 
backend bk_postfix
  mode tcp
  no option http-server-close
  log global
  option smtpchk
  timeout server 1m
  timeout connect 5s
  server postfix 192.168.126.137:9025 send-proxy check port 25
HAPROXYEX

cat > /etc/ha.d/ha.cf.example << HACFEX
debugfile /var/log/ha-debug
logfile /var/log/ha-log
logfacility     local0
keepalive 2
deadtime 5
initdead 60
udpport 694
ucast eth0 192.168.126.136
auto_failback off
node ha1.localdomain
node ha2.localdomain
HACFEX

cat > /etc/ha.d/haresources.example << HARESOURCESEX
ha1.localdomain IPaddr2::192.168.126.145/24
HARESOURCESEX

echo 'Installation done, now edit the ha.cf, haresources,haproxy bla bla according to your hosts file.Remeber to use static ips'
