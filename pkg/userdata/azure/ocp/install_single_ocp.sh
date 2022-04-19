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
sed -i 's|[#]*PasswordAuthentication no|PasswordAuthentication yes|g' /etc/ssh/sshd_config
sed -i 's|[#]*PermitRootLogin yes|PermitRootLogin yes|g' /etc/ssh/sshd_config
service sshd restart
systemctl restart sshd


#Antman Init
yum install -y /home/opsadmin/t-oceanbase-antman-1.3.8-1930157.alios7.x86_64.rpm
#Admin User Init
/root/t-oceanbase-antman/clonescripts/clone.sh -u
echo "admin:$adminpass" | chpasswd
#SYS Parameter Init
/root/t-oceanbase-antman/clonescripts/clone.sh -c -r ocp
/root/t-oceanbase-antman/clonescripts/clone.sh -m -r ocp

#Docker Init
/root/t-oceanbase-antman/clonescripts/clone.sh -i
#service docker start
#systemctl enable docker

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

echo "Install Ocp Complete" >>/root/install_ocp.log