# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box = "debian_squeeze_andrew_mcnaughty"
  config.vm.box_url = "http://andrew.mcnaughty.com/downloads/squeeze64_puppet27.box"
  config.vm.share_folder "logs", "/var/log", "logs", :extra => 'dmode=777,fmode=777', :create => true
  config.vm.share_folder "import", "/home/import", "artifacts", :extra => 'dmode=777,fmode=777', :create => true

  #convention: port a0bc goes to 4abc
  config.vm.forward_port 80, 4080
  config.vm.forward_port 443, 4443
  config.vm.forward_port 8080, 4880
  config.vm.forward_port 8081, 4881
  config.vm.forward_port 9000, 4900
  config.vm.forward_port 9001, 4901


  config.vm.provision :puppet do |puppet|
   puppet.manifests_path = "puppet/manifests"
   puppet.manifest_file = "default.pp"
   puppet.module_path  = "puppet/modules"

   puppet.facter = [
      [ "deploy_environment", "dev" ],
      [ "stuff_folder", "/vagrant" ],
   ]

  end
end