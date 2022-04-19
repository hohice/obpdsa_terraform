#!/bin/bash
# change opsadmin to root
sudo bash -c su -

#######################
#define password
rootpass=Obdba@123
adminpass=123456
#######################

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


#Antman Init
rpm -ivh https://oceanbasepdsa.oss-accelerate.aliyuncs.com/t-oceanbase-antman-1.3.7-1926785.alios7.x86_64.rpm

#SYS Parameter Init
/root/t-oceanbase-antman/clonescripts/clone.sh -u
echo "admin:$adminpass" | chpasswd
/root/t-oceanbase-antman/clonescripts/clone.sh -c -r ob
/root/t-oceanbase-antman/clonescripts/clone.sh -m -r ob

#File System config
mkdir -p /data/1
mkdir -p /data/log1
pvcreate /dev/nvme[1-8]n1
vgcreate vgob /dev/nvme[1-8]n1
lvcreate -L 2.5T -n oblog vgob
lvcreate -L 52T -n obdata vgob
mkfs.xfs /dev/mapper/vgob-oblog
mkfs.xfs /dev/mapper/vgob-obdata
mount /dev/mapper/vgob-oblog /data/log1/
mount /dev/mapper/vgob-obdata /data/1
chown -R admin:admin /data
echo '/dev/mapper/vgob-oblog /data/log1 xfs defaults 0 0' >> /etc/fstab
echo '/dev/mapper/vgob-obdata /data/1 xfs defaults 0 0'>> /etc/fstab


echo "Init Complete" >>/root/init_ob.log