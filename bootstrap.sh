#!/bin/bash
function install_pack () {
    if [ "$PACK" = "rpm" ];then
	yum -y install $1
    elif [ "$PACK" = "deb" ];then
	apt-get install $1 --quiet	-y
    fi
}

if output=$(cat /etc/*-release|grep ^NAME|cut -d'=' -f2|tr -d '"'| grep -i ubuntu); then
    PACK="deb"
    CODE_NAME=$(cat /etc/*-release|grep -i distrib_codename|cut -d= -f2)
elif output=$(cat /etc/*-release|grep ^NAME|cut -d'=' -f2|tr -d '"'| grep -i centos); then
    PACK="rpm"
fi


if [ "$PACK" = "rpm" ];then
    yum makecache fast
    rpm -Uvh https://yum.puppetlabs.com/puppet5/puppet5-release-el-7.noarch.rpm
elif [ "$PACK" = "deb" ];then
    wget "https://apt.puppetlabs.com/puppet5-release-${CODE_NAME}.deb" --quiet
    sudo dpkg -i "puppet5-release-${CODE_NAME}.deb"
    sudo apt-get update --quiet
fi


if [ "$1" = "master" ]; then
    install_pack puppetserver	

    if [ -f /etc/puppetlabs/puppet/puppet.conf ]; then
	find /etc/puppetlabs/puppet/ssl -name `hostname -f`.pem -exec rm -fr {} \;
	echo "Puppet server is already configured."
    else
	echo "autosign = /vagrant/autosign.conf" >> /etc/puppetlabs/puppet/puppet.conf
	echo "[agent]" >> /etc/puppetlabs/puppet/puppet.conf
	echo "server=puppet.local" >> /etc/puppetlabs/puppet/puppet.conf
	echo "environment=production" >> /etc/puppetlabs/puppet/puppet.conf
    fi
    
    if [ ! -L "/etc/puppetlabs/code/environments/production/manifests" ]; then
	rm -fr /etc/puppetlabs/code/environments/production/manifests
	ln -s /vagrant/manifests /etc/puppetlabs/code/environments/production/manifests
    fi
    
    if [ ! -L "/etc/puppetlabs/puppet/hiera.yaml" ]; then
	ln -s -f /vagrant/hiera.yaml /etc/puppetlabs/puppet/hiera.yaml
    fi
    
    PUPPET_CERTS=`/opt/puppetlabs/bin/puppet cert list --all`
    printf '%s\n' "$PUPPET_CERTS" | while IFS= read -r line
    do
	CERT_NAME=`echo $line | cut -d " " -f 2`
	CERT_FQDN="${CERT_NAME:1:-1}"
	THIS_FQDN=`hostname -f`
	if [ "$CERT_FQDN" != "$THIS_FQDN" ]; then
            puppet cert clean $CERT_FQDN 2> /dev/null
	fi
    done

    #Lower puppetservers default mem
    sed -i 's/Xms2g/Xms512m/g' /etc/sysconfig/puppetserver
    sed -i 's/Xmx2g/Xmx512m/g' /etc/sysconfig/puppetserver
    
    systemctl start puppetserver
else    
    if [ -f /etc/puppetlabs/puppet/puppet.conf ]; then
	find /etc/puppetlabs/puppet/ssl -name `hostname -f`.pem -exec rm -fr {} \;
	echo "Puppet Agent is already configured."
    else
	install_pack puppet-agent
	echo "[agent]" >> /etc/puppetlabs/puppet/puppet.conf
	echo "server=puppet.local" >> /etc/puppetlabs/puppet/puppet.conf
	echo "environment=production" >> /etc/puppetlabs/puppet/puppet.conf
    fi
    #we have no working dns server
    echo "192.168.32.180 puppet.local puppet" >> /etc/hosts
fi

