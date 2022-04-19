#!/bin/bash
#m5d.16xlarge
#ami-0ddea5e0f69c193a4



#Package Init
yum -y install docker wget lvm2 sysstat dstat expect mariadb mariadb-devel python-devel openssl-devel gcc gcc-gfortran gcc-c++ python-setuptools bc net-tools mtr ntp bind-utils libaio zlib-devel curl libcurl supervisor python-pip libffi libffi-devel libatomic MySQL-python make nc bridge-utils iproute

#Admin User Init
groupadd -g 500 admin
useradd  -d "/home/admin" -u 500 -g 500 -m -s /bin/bash admin
echo "admin:$adminpass" | chpasswd

#Antman Init
rpm -ivh https://oceanbasepdsa.oss-accelerate.aliyuncs.com/t-oceanbase-antman-1.3.7-1926785.alios7.x86_64.rpm
#SYS Parameter Init
/root/t-oceanbase-antman/clonescripts/clone.sh -c
#Docker Init
service docker start
systemctl enable docker

#File System config
mkdir -p /data/1
mkdir -p /data/log1
pvcreate /dev/nvme[1-4]n1
vgcreate vgob /dev/nvme[1-4]n1
lvcreate -L 512G -n oblog vgob
lvcreate -L 1.5T -n obdata vgob
mkfs.xfs /dev/mapper/vgob-oblog
mkfs.xfs /dev/mapper/vgob-obdata
mount /dev/mapper/vgob-oblog /data/log1/
mount /dev/mapper/vgob-obdata /data/1
chown -R admin:admin /data
echo '/dev/mapper/vgob-oblog /data/log1 xfs defaults 0 0' >> /etc/fstab
echo '/dev/mapper/vgob-obdata /data/1 xfs defaults 0 0'>> /etc/fstab

#Selinux init
sed -i 's/enforcing/disabled/g' /etc/selinux/config
/usr/sbin/setenforce 0

#OCP Install init
wget -P /root/t-oceanbase-antman https://oceanbasepdsa.oss-accelerate.aliyuncs.com/ocp_odc_20210510.tar.gz
tar xvf /root/t-oceanbase-antman/ocp_odc_20210510.tar.gz -C /root/t-oceanbase-antman
mv /root/t-oceanbase-antman/ocp/* /root/t-oceanbase-antman

sed -i "s|OCPHOSTIP|`echo $myhost`|g" /root/t-oceanbase-antman/obcluster.conf
sed -i "s|ROOTPASSWORD|`echo $rootpass`|g" /root/t-oceanbase-antman/obcluster.conf
sed -i "s|ADMINPASSWORD|`echo $adminpass`|g" /root/t-oceanbase-antman/obcluster.conf

#begin OCP install
cd /root/t-oceanbase-antman && ./install.sh -i 1-

#begin ODC install
cd /root/t-oceanbase-antman && ./install.sh -i 10

echo "UserData Complete" >>/root/user_data_init.log