# -*- mode: ruby -*-
# vi: set ft=ruby :

file_to_disk = '/tmp/large_disk.vdi'

Vagrant.configure("2") do |config|
  
  config.vm.box = "bento/centos-7"
	
  # disco adicional
  # vagrant plugin install vagrant-disksize
  # config.disksize.size = '40GB'
  
  config.vm.synced_folder ".", "/vagrant", type: 'virtualbox'

  config.vm.provider :virtualbox do |vb|
    vb.name = "pxe-server"
  end

	config.vm.define 'pxe-server' do |s|
		
    s.vm.hostname = "pxe-server.hans.lan"
    s.vm.network "private_network", ip: "192.168.200.10", :netmask => "255.255.255.0"
		
    config.vm.provision 'shell' do |shell|
      shell.path               = 'provision.sh'
      shell.privileged         = true
    end
	end
end
