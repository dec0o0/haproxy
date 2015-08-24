#!/bin/bash
yum -y update
sleep 1
yum install make wget gcc pcre-static pcre-develha
wget http://haproxy.1wt.eu/download/1.5/src/devel/haproxy-1.5-dev7.tar.gz
tar -zxf haproxy-1.5-dev7.tar.gz 
cd haproxy-1.5-dev7
make TARGET=linux26 USE_STATIC_PCRE=1 USE_LINUX_TPROXY=1
cp haproxy /usr/sbin/haproxy
echo ' installation complete'
