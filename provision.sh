echo "provision v3";

systemctl restart network;

# resolve firewalld issue
#unlink /etc/systemd/system/firewalld.service;
#systemctl enable firewalld;
#systemctl start firewalld;

# basic SO dependencies
yum install -y centos-release net-tools vim curl wget;

# pxe dependecies 
yum install -y dhcp tftp tftp-server vsftpd syslinux xinetd;

systemctl enable xinetd --now;
systemctl enable dhcpd.service --now;
systemctl enable tftp.service --now;
systemctl enable vsftpd.service --now;

# configuration

# prefer enp0s8
echo DHCPDARGS=enp0s8 >> /etc/sysconfig/dhcpd

cat <<EOF > /etc/dhcp/dhcpd.conf 
  # DHCP Server Configuration file.

  ddns-update-style interim;
  ignore client-updates;
  authoritative;
  allow booting;
  allow bootp;
  allow unknown-clients;

  default-lease-time 3600; 

  # internal subnet for my DHCP Server
  subnet 192.168.200.0 netmask 255.255.255.0 {
    option routers                  192.168.200.10;
    option subnet-mask              255.255.255.0;
    option domain-name              "hans.lan";
    option domain-name-servers      192.168.200.10;
    option broadcast-address 192.168.200.255;
    range   192.168.200.10   192.168.200.100;
    range   192.168.200.120  192.168.200.200;

    default-lease-time 3600; 
    max-lease-time 7200;
    
    # PXE boot server
    next-server 192.168.200.10;
    filename "pxelinux.0";
  }

  # PXE boot server
  next-server 192.168.200.10;
  filename "pxelinux.0";

EOF

cat <<EOF > /etc/xinetd.d/tftp
# default: off
# description: The tftp server serves files using the trivial file transfer \
#       protocol.  The tftp protocol is often used to boot diskless \
#       workstations, download configuration files to network-aware printers, \
#       and to start the installation process for some operating systems.
service tftp
{
        socket_type             = dgram
        protocol                = udp
        wait                    = yes
        user                    = root
        server                  = /usr/sbin/in.tftpd
        server_args             = -s /var/lib/tftpboot
        #disable                 = yes
        disable                 = no
        per_source              = 11
        cps                     = 100 2
        flags                   = IPv4
}
EOF

cp -v /usr/share/syslinux/pxelinux.0 /var/lib/tftpboot
cp -v /usr/share/syslinux/menu.c32 /var/lib/tftpboot
cp -v /usr/share/syslinux/memdisk /var/lib/tftpboot
cp -v /usr/share/syslinux/mboot.c32 /var/lib/tftpboot
cp -v /usr/share/syslinux/chain.c32 /var/lib/tftpboot

mkdir /var/lib/tftpboot/pxelinux.cfg
mkdir /var/lib/tftpboot/networkboot

# cd /vagrant/
# curl -LO http://ftp.unicamp.br/pub/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso

# mount SO 
mount -o loop /vagrant/CentOS-7-x86_64-Minimal-2009.iso /mnt/

cd /mnt/

cp -av * /var/ftp/pub/

cd /

cp /mnt/images/pxeboot/vmlinuz /var/lib/tftpboot/networkboot/

cp /mnt/images/pxeboot/initrd.img /var/lib/tftpboot/networkboot/

umount /mnt/

# kickstart file
cat <<END > /var/ftp/pub/centos7.ks

cmdline

install

url --url="ftp://192.168.200.10/pub/"

text

lang en_US.UTF-8

firstboot --disable

keyboard us

timezone --utc America/Sao_Paulo

network --device enp0s8 --onboot yes --bootproto dhcp

# To generate password use: openssl passwd -1 -salt abc yourpass
# rootpw --iscrypted \$1\$abc\$eXT.vKU2cv.5/y/x/JA1H/ # yourpass
rootpw --iscrypted \$1\$abc\$6oqhhS8I7kjelvdsew.cJ/
firewall --disabled
authconfig --enableshadow --passalgo=sha512
selinux --disabled

services --enabled=sshd

# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
part /boot --asprimary --fstype=xfs --size=1024

# Disk configuration
zerombr
ignoredisk --only-use=sda
clearpart --all --drives=sda

# Criando LVM com o tamanho total do disco
part pv.253 --fstype="lvmpv" --ondisk=sda --size=1 --grow
volgroup vg_lvm --pesize=4096 pv.253
logvol swap  --fstype="swap" --size=4096 --name=swap --vgname=vg_lvm
logvol /     --fstype="xfs"  --size=5120 --name=root --vgname=vg_lvm
logvol /tmp  --fstype="xfs"  --size=1024 --name=tmp  --vgname=vg_lvm --fsoptions="nosuid,noexec"
logvol /var  --fstype="xfs"  --size=4096 --name=var  --vgname=vg_lvm
logvol /opt  --fstype="xfs"  --size=1024 --name=opt  --vgname=vg_lvm
logvol /home --fstype="xfs"  --size=1024 --name=home --vgname=vg_lvm

%packages --ignoremissing
@core
%end

%post

# Vagrant:
useradd  -m -d /home/vagrant -s /bin/bash -p '$6$rounds=1000000$KKaL8Z6CY+YxSbNh$CfE6VGt92n6ESZOhYPRO7hMwBhoFpYCPwc7qqjPPEdJzp8kpkPCUA46zLDyuLgcnMaF32mFuaiukmCC3jSmQk/' -c "Vagrant Administrator" vagrant
mkdir /home/vagrant/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key" > /home/vagrant/.ssh/authorized_keys

%end

# Reboot after installation
reboot

END

# improved pxe boot menu
cat <<END > /var/lib/tftpboot/pxelinux.cfg/default
PROMPT 0
#TIMEOUT 30
#NOESCAPE 0
#ALLOWOPTIONS 0

### TUI
DEFAULT menu.c32

### GUI
#UI vesamenu.c32
# The splash.png file is a PNG image with resolution of 640x480 px
#MENU BACKGROUND splash.png

MENU TITLE ---===[ Hans :] PXE Boot Menu ]===---

LABEL local
  MENU DEFAULT
  MENU LABEL ^1. Boot from hard drive
  COM32 chain.c32
  APPEND hd0

LABEL centos7_x64
  MENU LABEL ^2. CentOS 7_X64
  KERNEL /networkboot/vmlinuz
  APPEND initrd=/networkboot/initrd.img inst.repo=ftp://192.168.200.10/pub ks=ftp://192.168.200.10/pub/centos7.ks
END

# enable and start
systemctl enable xinetd;
systemctl enable dhcpd.service;
systemctl enable tftp.service;
systemctl enable tftp.socket
systemctl enable vsftpd.service; 

systemctl restart xinetd;
systemctl restart dhcpd.service; 
systemctl restart tftp.service; 
systemctl start tftp.socket;
systemctl restart vsftpd.service;

chmod -R 755 /var/lib/tftpboot/
chmod -R 755 /var/ftp/

# firewall rules
#firewall-cmd --permanent --add-service={dhcp,proxy-dhcp};
#firewall-cmd --permanent --add-service=tftp;
#firewall-cmd --permanent --add-service=ftp;
#firewall-cmd --permanent --add-port=21/tcp;
#firewall-cmd --permanent --add-port=69/tcp;
#firewall-cmd --permanent --add-port=69/udp;
#firewall-cmd --permanent --add-port=4011/udp;

###firewall-cmd --permanent --remove-port={69/tcp,69/udp,4011/udp}
###firewall-cmd --permanent --remove-service={dhcp,proxy-dhcp,ftp}

#firewall-cmd --reload;

#firewall-cmd --list-all;

#systemctl restart network;


# check services
echo "Check services";

systemctl status tftp.service;
systemctl status vsftpd.service;
systemctl status xinetd.service;
systemctl status dhcpd.service;

ip a;