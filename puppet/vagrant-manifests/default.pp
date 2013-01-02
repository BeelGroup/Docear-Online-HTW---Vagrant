Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", ] }

exec { 'apt-get-update':
  command => '/usr/bin/apt-get update'
}

#http://projects.puppetlabs.com/projects/1/wiki/Debian_Apache2_Recipe_Patterns
class apache {
  package { "apache2":
    ensure => present,
    require => Exec['apt-get-update'],
  }

  define module ( $ensure = 'present') {
    case $ensure {
      'present' : {
        exec { "/usr/sbin/a2enmod $name":
          unless => "/bin/readlink -e ${apache2_mods}-enabled/${name}.load",
          notify => Exec["force-reload-apache2"],
          require => Package["apache2"],
        }
      }
      'absent': {
        exec { "/usr/sbin/a2dismod $name":
          onlyif => "/bin/readlink -e ${apache2_mods}-enabled/${name}.load",
          notify => Exec["force-reload-apache2"],
          require => Package["apache2"],
        }
      }
      default: { err ( "Unknown ensure value: '$ensure'" ) }
    }
  }

  exec { "reload-apache2":
    command => "/etc/init.d/apache2 reload",
    refreshonly => true,
  }

  exec { "force-reload-apache2":
    command => "/etc/init.d/apache2 force-reload",
    refreshonly => true,
  }

  module { "proxy":  }
  module { "proxy_http":  }
  module { "proxy_balancer":  }

  file { "apache-conf":
      path    => "/etc/apache2/sites-available/default",
      content => template("/vagrant/puppet/vagrant-manifests/apache-virtual-host.erb"),
      require  => Package["apache2"]
  }

  service { "apache2":
    ensure => running,
    require => [Package["apache2"], File["apache-conf"]],
  }
}

include apache

#coreutils contains nohup
package { "packages":
  name => ["openjdk-6-jre", "unzip", "coreutils", "xvfb", "screen"],
  ensure => present,
  require => Exec['apt-get-update'],
}

define play::extract_from_zip($zip, $target, $play_app_name_version) {
  $tmp_folder_for_unpacked = "/tmp/playapp"

  exec {"cp-play-dist ${target}":
    command => "rm -rf ${tmp_folder_for_unpacked} && mkdir ${tmp_folder_for_unpacked} && unzip ${$zip} -d ${$tmp_folder_for_unpacked}",
    cwd => "/",
    require => Package["packages"],
  }

  file { "play-instance ${target}":
    path => $target,
    ensure => "directory",
    recurse => remote,
    source => "${$tmp_folder_for_unpacked}/${$play_app_name_version}",
    require =>  Exec["cp-play-dist ${target}"],
    owner => "vagrant",
    group => "vagrant",
  }
}

define play::application ($port, $path, $ensure = running){
  if $ensure == running {
    exec { "run ${path} ${port}":
      command => "nohup bash start -Dhttp.port=${$port} &",
      cwd => $path,
      user => "vagrant",
      group => "vagrant",
    }
  }
}

define run_play_app($port, $path) {
  $play_zip = "/vagrant/artifacts/play/${play_app_name_version}.zip"

  play::extract_from_zip { "play-instance ${port}":
    zip => $play_zip,
    target => $path,
    play_app_name_version => $play_app_name_version
  }

  #TODO# remove RUNNING_PID file

  play::application { "node ${port}":
    ensure => running,
    port => $port,
    path => $path,
    require => Play::Extract_from_zip["play-instance ${port}"],
  }
}

run_play_app { "node 1":
  port => 9000,
  path => "/opt/play-instance-1",
}

run_play_app { "node 2":
  port => 9001,
  path => "/opt/play-instance-2",
}

define docear::extract_from_tar($target) {
  $tmp_folder_for_unpacked = "/tmp/docear_untar_folder"
  $tar_name = "docear_linux.tar.gz"
  $docear_folder_name = $docear_app_name_version

  exec {"extract ${target}":
      command => "rm -rf ${tmp_folder_for_unpacked} && mkdir ${tmp_folder_for_unpacked} && tar -xvzf ${tar_name} -C ${$tmp_folder_for_unpacked}",
      cwd => "/vagrant/artifacts/docear",
      require => Package["packages"],
  }

  file { "docear cp ${target}":
      path => $target,
      ensure => "directory",
      recurse => remote,
      source => "${$tmp_folder_for_unpacked}/${docear_folder_name}",
      require =>  Exec["extract ${target}"],
      owner => "vagrant",
      group => "vagrant",
  }
}

define docear::backend_application ($port, $path, $ensure = running){
  if $ensure == running {
    $screen = 6 + $port - 8080
    exec { "run ${path} ${port}":
        command => "screen -L -d -m xvfb-run --auto-servernum -s \"-screen ${screen} 1280x1024x24\" bash docear.sh &",
        environment => "webservice_port=${port}",
        cwd => $path,
        user => "vagrant",
        group => "vagrant",
        require => Package["packages"],
    }
  }
}

#TODO smaller scope
$home = "/home/vagrant"

file { "$home/.docear":
    ensure => directory,
    recurse => true,
    owner => "vagrant",
    group => "vagrant",
}

$workspace_absolute_path = "${$home}/docear-workspace"
file {"docear auto.properties":
    path => "${home}/.docear/auto.properties",
    ensure  => file,
    content => template("/vagrant/puppet/vagrant-manifests/docear-home/auto.properties.erb"),
    require => File["$home/.docear"],
}

define run_docear_app($port, $path) {
  docear::extract_from_tar {"docear instance $path":
      target => $path
  }

  docear::backend_application {
    "docear $path":
    port => $port,
    path => $path,
    ensure => running,
    require => [Docear::Extract_from_tar["docear instance $path"], File["docear auto.properties"]],
  }

  file { "${path}/screenlog.0":
      path => "${path}/screenlog.0",
      ensure => 'link',
      target => "/vagrant/logs/docear-${port}.log",
      require => Docear::Backend_application["docear $path"],
  }
}

run_docear_app { "instance 1":
  port => 8080,
  path => "/opt/docear-instance-1",
}

run_docear_app { "instance 2":
  port => 8081,
  path => "/opt/docear-instance-2",
}

#TODO copy property-files in docear home!!!
#/home/vagrant/.docear
 #TODO logging???
#TODO use different users
