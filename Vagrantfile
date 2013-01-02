# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box = "debian_squeeze_andrew_mcnaughty"
  config.vm.box_url = "http://andrew.mcnaughty.com/downloads/squeeze64_puppet27.box"

  config.vm.forward_port 80, 4080
  #convention: port a0bc goes to 4abc
  config.vm.forward_port 8080, 4880
  config.vm.forward_port 8081, 4881
  config.vm.forward_port 9000, 4900
  config.vm.forward_port 9001, 4901


  config.vm.provision :puppet do |puppet|
   puppet.manifests_path = "puppet/vagrant-manifests"
   puppet.manifest_file = "default.pp"
   puppet.module_path  = "puppet/modules"

   play_zip_name = Dir.foreach('artifacts/play').find_all{|item| item.end_with?(".zip") }.first
   play_app_name_version = nil
   if !play_zip_name.nil?
       play_app_name_version = play_zip_name.gsub(".zip", "")
   end

   docear_app_name_version = IO.read("artifacts/docear/version.txt")

   puppet.facter = [
      [ "play_app_name_version", play_app_name_version ],
      [ "docear_app_name_version", docear_app_name_version ]
   ]

  end
end