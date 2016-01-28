
#Actualizamos el Sistema: 
yum update

#Instalamos los paquetes lvm y xhost
yum install xhost lvm2

#Configuramos ntp
rm /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Madrid /etc/localtime

#Paramos firewalls
service iptables stop
service ip6tables stop
chkconfig iptables off
chkconfig ip6tables off

#Añadimos los discos extras
fdisk -l
vgcreate u01 /dev/xvdb
vgdisplay
lvcreate --name oracle -l 100%FREE u01
lvscan
lvdisplay
mkfs.ext4 /dev/u01/oracle
mkdir /u01/oracle
mount /dev/u01/oracle /u01/oracle
df -h
vi /etc/fstab
reboot
df -h

#Crear usuario Oracle
groupadd -g 500 oinstall
groupadd -g 501 dba
useradd -u 501 -g oinstall -G dba -d /home/oracle oracle
chown oracle:oinstall /u01/oracle/
passwd oracle