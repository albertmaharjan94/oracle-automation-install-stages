#!/bin/bash
echo "Making directory on /stage/Disk1"
mkdir -p /stage/Disk1
echo "Done"

echo "Copying media to disk 1"
if [ -d "/media/OL6.7 x86_64 Disc 1 20150728" ] 
then
    echo "Found Media" 
else
    echo "Media not found exiting"
    exit 1
fi
cp -v -r /media/OL6.7\ x86_64\ Disc\ 1\ 20150728/* /stage/Disk1
sync
echo "Done"

cd /stage/Disk1/Packages

echo "Installing dependencies"
rpm -ivh createrepo-0.9.9-22.el6.noarch.rpm deltarpm-3.5-0.5.20090913git.el6.x86_64.rpm  python-deltarpm-3.5-0.5.20090913git.el6.x86_64.rpm
sync
echo "Done"
echo "Creating repo"
createrepo /stage/Disk1/Packages
sync
echo "Done"

cd /etc/yum.repos.d
echo "Creating offline package manager"
echo "[server]
name=server's packages
baseurl=file:///stage/Disk1/Packages
enabled=1
gpgcheck=0" > pacakges.repo
echo "Done"
echo "Removing public package manage"
rm -rf public-yum-ol6.repo
echo "Done"

echo "Installing yum dependencies"
yum -y install binutils-2*x86_64* glibc-2*x86_64* nss-softokn-freebl-3*x86_64* glibc-2*i686* nss-softokn-freebl-3*i686* compat-libstdc++-33*x86_64* glibc-common-2*x86_64* glibc-devel-2*x86_64* glibc-devel-2*i686* glibc-headers-2*x86_64* elfutils-libelf-0*x86_64* elfutils-libelf-devel-0*x86_64* gcc-4*x86_64* gcc-c++-4*x86_64* ksh-*x86_64* libaio-0*x86_64* libaio-devel-0*x86_64* libaio-0*i686* libaio-devel-0*i686* libgcc-4*x86_64* libgcc-4*i686* libstdc++-4*x86_64* libstdc++-4*i686* libstdc++-devel-4*x86_64* make-3.81*x86_64* numactl-devel-2*x86_64* sysstat-9*x86_64* compat-libstdc++-33*i686* compat-libcap*
sync
echo "Done"

echo "Configuring kernel"

echo "kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
fs.file-max = 6815744
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576" >> /etc/sysctl.conf
sysctl -p
echo "Done"

echo "Configuring security limits"
echo "oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
grid soft nproc 2047
grid hard nproc 16384
grid soft nofile 1024
grid hard nofile 65536" >> /etc/security/limits.conf
echo "Done"

echo "Configuring firewall"
iptables -F
service iptables save
chkconfig iptables off
echo "Done"

echo "Configuring selinux"
setenforce 0
cd /etc/sysconfig/
sed '7s/.*/SELINUX=disabled/' selinux > selinux_tmp
mv -f selinux_tmp selinux
echo "Done"

echo "Creating users and group"
groupadd asmadmin
groupadd asmdba
groupadd asmoper
groupadd oinstall
groupadd dba
groupadd oper

useradd -g oinstall -G dba,asmadmin,asmdba,asmoper -d /home/grid grid
useradd -g oinstall -G dba,oper,asmdba -d /home/oracle oracle
echo "Done"
echo "Configuring password to oracle and grid"
passwd grid<<EOF
password
password
sync
EOF

passwd oracle<<EOF
password
password
sync
EOF
echo "Done"

echo "Creating grid and oracle directories"
mkdir -p /u01/app/grid
mkdir -p /u01/app/11.2.0/grid
chown -R grid:oinstall /u01
mkdir -p /u01/app/oracle
chown oracle:oinstall /u01/app/oracle
chmod -R 775 /u01
echo "Done"


echo "Configuring oracle bash profile"
echo "ORACLE_HOSTNAME=localhost.localdomain; export ORACLE_HOSTNAME
ORACLE_SID=orcl; export ORACLE_SID
ORACLE_UNQNAME=orcl; export ORACLE_UNQNAME
JAVA_HOME=/usr/local/java; export JAVA_HOME
ORACLE_BASE=/u01/app/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1; export ORACLE_HOME
ORACLE_TERM=xterm; export ORACLE_TERM
NLS_DATE_FORMAT="\""DD-MON-YYYY HH24:MI:SS"\""; export NLS_DATE_FORMAT
TNS_ADMIN=$ORACLE_HOME/network/admin; export TNS_ADMIN
ORA_NLS11=$ORACLE_HOME/nls/data; export ORA_NLS11
PATH=.:${JAVA_HOME}/bin:${PATH}:$HOME/bin:$ORACLE_HOME/bin
PATH=${PATH}:/usr/bin:/bin:/usr/bin/X11:/usr/local/bin
PATH=${PATH}:/u01/app/common/oracle/bin
export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/JRE
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/rdbms/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/network/jlib
export CLASSPATH
THREADS_FLAG=native; export THREADS_FLAG
export TEMP=/tmp
export TMPDIR=/tmp
umask 022" >> /home/oracle/.bash_profile
sync
echo "Done"

echo "Configuring grid bash profile"
echo "ORACLE_HOSTNAME=localhost.localdomain; export ORACLE_HOSTNAME
ORACLE_SID=+ASM; export ORACLE_SID
JAVA_HOME=/usr/local/java; export JAVA_HOME
ORACLE_BASE=/u01/app/grid; export ORACLE_BASE
ORACLE_HOME=/u01/app/11.2.0/grid; export ORACLE_HOME
ORACLE_TERM=xterm; export ORACLE_TERM
NLS_DATE_FORMAT="\""DD-MON-YYYY HH24:MI:SS"\""; export NLS_DATE_FORMAT
TNS_ADMIN=$ORACLE_HOME/network/admin; export TNS_ADMIN
ORA_NLS11=$ORACLE_HOME/nls/data; export ORA_NLS11
PATH=.:${JAVA_HOME}/bin:${PATH}:$HOME/bin:$ORACLE_HOME/bin
PATH=${PATH}:/usr/bin:/bin:/usr/bin/X11:/usr/local/bin
PATH=${PATH}:/u01/app/common/oracle/bin
export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$ORACLE_HOME/oracm/lib
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/lib:/usr/lib:/usr/local/lib
export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/JRE
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/rdbms/jlib
CLASSPATH=${CLASSPATH}:$ORACLE_HOME/network/jlib
export CLASSPATH
THREADS_FLAG=native; export THREADS_FLAG
export TEMP=/tmp
export TMPDIR=/tmp
umask 022" >> /home/grid/.bash_profile
sync
echo "Done"


echo "Creating fdisk"
_latest="$(fdisk -l | grep /dev/sda | tail -1)"
_latest_array=($_latest)
_end_cylinder=${_latest_array[1]}
echo "Start fdisk"
sda_first=$(($(echo "${_latest_array[0]}" | grep -o -E '[0-9]+')+1))

for i in {0..6}
do
 _latest="$(fdisk -l | grep /dev/sda | tail -1)"
 _latest_array=($_latest)
 _end_cylinder=${_latest_array[1]}
 _start_cylinder=$((_end_cylinder+1))
 echo "This is ${_start_cylinder}"
 sync
 (echo n; echo $start_cylinder; echo +5G; echo w) | fdisk /dev/sda
 sync
done

# The first disk partition gets bugged, i cannot figure out why so deleting the first created sda
echo "Deleting sda $sda_first"
(echo d; echo $sda_first; echo w) | fdisk /dev/sda
sync
echo "Done"
echo "Rebooting in 5 seconds...."
sleep 5
reboot
