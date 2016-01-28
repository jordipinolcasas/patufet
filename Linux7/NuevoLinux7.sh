

#Configuracion IP 
yum info net-tools
nmcli device status	
DEVICE  TYPE      STATE        CONNECTION 
enp0s3  ethernet  disconnected --
lo      loopback  unmanaged    --

#Aixecar la IP
nmcli connection up enp0s3

#Definir la IP
nmcli connection modify enp0s3 \
      +ipv4.addresses "192.168.1.2/24 192.168.1.1"

nmcli connection up enp0s3

#Configurar DNS
nmcli connection modify enp0s3 \
      ipv4.dns 192.168.1.1

#Actualizamos el Sistema: 
yum update


#Parar firewall
service firewalld stop


#Instalamos los paquetes lvm y xhost
yum install xhost lvm2

#Configuramos ntp
rm /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Madrid /etc/localtime

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