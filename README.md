# Docker-Rally
Deploying a RHEL-based Rally container for performance testing.  It is assumed that this will be hosted on a OSP Director host, but it's not a requirement.  This work is derived from the Rally Docker file and docs at the below sites: 

http://rally.readthedocs.org/en/latest/install.html#rally-docker
https://github.com/openstack/rally/blob/master/Dockerfile

## Docker Setup
```
# Note - Docker is in the rhel-7-server-extras-rpms repo
yum -y install docker
systemctl enable docker && systemctl start docker
docker info 
docker pull rhel7
```

## Build and run your Rally container
This assumes your host is properly subscribed and the necessary repos are enaled.  If using local repos, create a rhelosp7.repo repofile and uncomment the copy line in the docker file
```
# Can't get rally to create the sqlite DB with selinux enabled
setenforce 0 
## Edit /etc/sysconfig/selinux to set Permissive rather than Enforcing
cd /root
git clone https://github.com/jonjozwiak/docker-rally.git
git clone https://github.com/openstack/rally.git
cd rally
mv Dockerfile Dockerfile.ubuntu
cp ../docker-rally/Dockerfile `pwd`
docker build -t osp-rally .
mkdir /var/lib/rally_container
cd /var/lib/rally_container
git clone https://github.com/jtaleric/browbeat.git
chown 65500 /var/lib/rally_container
chcon -Rt svirt_sandbox_file_t /var/lib/rally_container/
docker run -it -v /var/lib/rally_container:/home/rally osp-rally
```

## In the container add your OpenStack deployment
```
### Update below to match your environment
cat << EOF >> overcloudrc
export OS_USERNAME=admin
export OS_TENANT_NAME=admin
export OS_AUTH_URL=http://xxx.xxx.xxx.xxx:5000/v2.0/
export OS_PASSWORD=MyPasswordHere
EOF
. overcloudrc
rally deployment create --fromenv --name=osp7
```
