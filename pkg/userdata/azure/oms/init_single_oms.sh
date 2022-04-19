#!/bin/bash
# change opsadmin to root
sudo bash -c su -


#########################
#define password
rootpass=Obdba@123
adminpass=123456
#########################

#define IP
myhost=`hostname -i`


#Turn on password authentication for OceanBase Machines
echo $rootpass | passwd --stdin root

#Selinux init
sed -i 's/enforcing/disabled/g' /etc/selinux/config
/usr/sbin/setenforce 0

sed -i 's|[#]*PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config
sed -i 's|[#]*PermitRootLogin yes|PermitRootLogin yes|g' /etc/ssh/sshd_config
service sshd restart
systemctl restart sshd

#Package Init
yum -y install docker wget lvm2 sysstat dstat expect mariadb mariadb-devel python-devel openssl-devel gcc gcc-gfortran gcc-c++ python-setuptools bc net-tools mtr ntp bind-utils libaio zlib-devel curl libcurl supervisor python-pip libffi libffi-devel libatomic MySQL-python make nc bridge-utils iproute



#Antman Init
rpm -ivh https://oceanbasepdsa.oss-accelerate.aliyuncs.com/t-oceanbase-antman-1.3.7-1926785.alios7.x86_64.rpm
#Admin User Init
/root/t-oceanbase-antman/clonescripts/clone.sh -u
echo "admin:$adminpass" | chpasswd
#SYS Parameter Init
/root/t-oceanbase-antman/clonescripts/clone.sh -c


#Docker Init
/root/t-oceanbase-antman/clonescripts/clone.sh -i
#service docker start
#systemctl enable docker

#Image Init
wget -P /root https://oceanbasepdsa.oss-accelerate.aliyuncs.com/influxdb_1.8.tar.gz
wget -P /root  https://oceanbasepdsa.oss-accelerate.aliyuncs.com/oms.feature_2.2.0_beta.202104302057.tar.gz

#File System config
mkdir -p /data/
mkdir -p /data/fluxdata
pvcreate /dev/nvme[1-4]n1
vgcreate vgoms /dev/nvme[1-4]n1
lvcreate -L 3.2T -n omsdata vgoms
mkfs.xfs /dev/mapper/vgoms-omsdata
mount /dev/mapper/vgoms-omsdata /data/
chown -R admin:admin /data
echo '/dev/mapper/vgoms-omsdata /data/ xfs defaults 0 0' >> /etc/fstab

#OMS Install init
docker load -i /root/influxdb_1.8.tar.gz
docker load -i /root/oms.feature_2.2.0_beta.202104302057.tar.gz
docker run -d -p 8086:8086 -v /data/fluxdata:/var/lib/influxdb --name=oms-influxdb influxdb:1.8
sleep 5
docker exec -it oms-influxdb influx -execute "create user admin with password '123456'  WITH ALL PRIVILEGES"

#config init
wget -P /root https://oceanbasepdsa.oss-accelerate.aliyuncs.com/config.yaml
sed -i "s|MYHOST|`echo $myhost`|g" /root/config.yaml
wget -P /root https://oceanbasepdsa.oss-accelerate.aliyuncs.com/oms_init.sh
chmod 777 /root/oms_init.sh


echo "Init Oms Complete" >>/root/init_oms.log