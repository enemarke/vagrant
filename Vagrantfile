# vi: set ft=ruby :
# Based on:
# Builds Puppet Master and multiple Puppet Agent Nodes using JSON config file
# Author: Gary A. Stafford

# read vm and chef configurations from JSON files
class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  def light_blue
    colorize(36)
  end
end

nodes_config = (JSON.parse(File.read("nodes.json")))['nodes']
puppet_source = ENV['PUPPET_PATH']
puppet_required_version = ENV['PUPPET_MAJOR_VERSION']

if puppet_required_version
  puppet_major_version = puppet_required_version
else
  puppet_major_version = "4"
end

unless puppet_major_version =~ /4/
  puts "Only PUPPET_MAJOR_VERSION 4 is supported. Please correct it, current values is #{puppet_major_version}."
  exit
end

if puppet_source == nil
  puts "Please set PUPPET_PATH to your environment"
  exit
end

VAGRANTFILE_API_VERSION = "2"

PUPPET_SOURCE = '/etc/puppetlabs/code/environments/production'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  nodes_config.each do |node|
    node_name = node[0] # name of node

    if node_name == 'puppet'
      config.vm.define "puppet", primary: true
    else
      config.vm.define node_name.to_s, autostart: false
    end

    config.vm.define node_name do |node_config|
       if node_name =~ /puppet|foreman01/
        node_config.vm.synced_folder "#{puppet_source}/modules", "#{PUPPET_SOURCE}/modules",
                                id: "puppet-module",
                                :owner => '996',
                                :group => '994',
                                :mount_options => ["dmode=755,fmode=664"]
        node_config.vm.synced_folder ".", "/mnt/puppettest",
                                     id: "puppet-manifests",
                                     :owner => '996',
                                     :group => '994',
                                     :mount_options => ["dmode=775,fmode=664"]
      else
        node_config.vbguest.no_install = true
        node_config.vm.synced_folder ".", "/vagrant", disabled: true
      end

      node_values = node[1] # content of node
      # configures all forwarding ports in JSON array
      ports = node_values['ports']
      unless ports.nil?
        ports.each do |port|
          node_config.vm.network :forwarded_port,
                            host: port[':host'],
                            guest: port[':guest'],
                            id: port[':id']
        end
      end

      node_config.vm.provision :shell,
                          :run => "always",
                          :path => node_values['bootstrap'],
                          :args => node_values['bootstrap_args']
      node_config.vm.box = node_values['nodeOS']
      node_config.vm.hostname = node_values[':hostname']
      node_config.vm.network :private_network, ip: node_values[':ip']

      node_config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--cpus", 2]
        vb.customize ["modifyvm", :id, "--memory", node_values[':memory']]
        vb.customize ["modifyvm", :id, "--name", node_name]
        vb.customize ["modifyvm", :id, "--vram", "34"]
        if node_values['nodeOS'] == 'ubuntu/trusty64'
          vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
          vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
          vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        end
      end
    end
  end
end


