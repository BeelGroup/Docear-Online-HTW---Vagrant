notify{"The deploy_environment is: ${deploy_environment}": }

Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", ] }

exec { 'apt-get-update':
  command => '/usr/bin/apt-get update'
}

define add_user($username, $full_name, $home, $shell = "/bin/bash", $main_group = "$username", $groups = [], $ssh_key = "", $ssh_key_type = "") {
  user { $username:
      comment => "$full_name",
      home    => "$home",
      shell   => "$shell",
      managehome => true,
      gid => "$main_group",
      groups => $groups,
      require => [Group["$username"]]
  }

  if $ssh_key {
      ssh_authorized_key{ $username:
          user => "$username",
          ensure => present,
          type => "$ssh_key_type",
          key => "$ssh_key",
          name => "$username",
          require => User[$username]
      }
  }

  group { $username:
      ensure => "present",
  }

  file {"$home init rights":
      path => $home,
      ensure  => "directory",
      mode  => '0660',
      owner => $username,
      group => $username,
      recurse => true,
      require => User[$username]
  }
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
          require => Package["apache2"],
        }
      }
      'absent': {
        exec { "/usr/sbin/a2dismod $name":
          onlyif => "/bin/readlink -e ${apache2_mods}-enabled/${name}.load",
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
  module { "ssl":  }
  module { "headers":  }
  module { "rewrite":  }

  file { "ssl-server-crt ":
      path    => "/etc/ssl/certs/server.crt",
      content => template("$stuff_folder/puppet/manifests/ssl/new.cert.cert.erb"),
      require  => Package["apache2"]
  }
  file { "ssl-server-key ":
      path    => "/etc/ssl/private/server.key",
      content => template("$stuff_folder/puppet/manifests/ssl/new.cert.key.erb"),
      require  => Package["apache2"]
  }

  file { "apache-conf":
      path    => "/etc/apache2/sites-available/default",
      content => template("$stuff_folder/puppet/manifests/apache-virtual-host.erb"),
      require  => [Package["apache2"], Module["proxy"], Module["proxy_http"], Module["proxy_balancer"], Module["ssl"], Module["headers"], File["ssl-server-crt "], File["ssl-server-key "]],
      notify => Exec["force-reload-apache2"],
  }

  service { "apache2":
    ensure => running,
    require => [Package["apache2"], File["apache-conf"]],
  }
}

include apache

#coreutils contains nohup
package { "packages":
  name => ["openjdk-6-jre", "unzip", "coreutils", "xvfb", "screen", "vim", "sudo"],
  ensure => present,
  require => Exec['apt-get-update'],
}

$play_frontend_username = "play-frontend"
$play_frontend_home = "/var/$play_frontend_username"
$play_application_path = "$play_frontend_home/current"
$play_config_resource = $deploy_environment ? {
    'dev' =>  "staging.conf",
    'staging' => "staging.conf",
    'prod' => "prod.conf"
}
$play_frontend_version = "docear-frontend-0.1-SNAPSHOT"

add_user { "$play_frontend_username":
  username => "$play_frontend_username",
  full_name => "play frontend server",
  home => $play_frontend_home,
}

define add_init_script($name, $application_path, $start_command, $user, $group, $pid_file, $current_working_dir) {

  file {"/etc/init.d/$name":
      content => template("$stuff_folder/puppet/manifests/init-with-pid.erb"),
      ensure => present,
      group => "root",
      owner => "root",
      mode => 750,
  }

  exec {"activate /etc/init.d/$name":
      command => "sudo update-rc.d $name defaults",
      require => File["/etc/init.d/$name"]
  }
}

add_init_script {"$play_frontend_username":
  name => "$play_frontend_username",
  application_path => $play_application_path,
  start_command => "$play_application_path/start -Dconfig.resource=$play_config_resource -Dhttp.port=9000 -Dhttp.address=127.0.0.1 -Ddb.default.url=jdbc:h2:file:/tmp/play-frontend/h2/data",
  user => "$play_frontend_username",
  group => "$play_frontend_username",
  pid_file => "$play_application_path/RUNNING_PID",
  current_working_dir =>"$play_frontend_home",
  require => [Add_user[$play_frontend_username], File["$play_application_path start rights"]]
}

exec { 'unzip play':
      command => "rm -rf ${play_frontend_version} && unzip ${play_frontend_version}.zip && sudo rm -rf $play_application_path && sudo mv ${play_frontend_version} $play_application_path",
      cwd => "$stuff_folder/artifacts",
      require => [Package["packages"], Add_user["$play_frontend_username"]],
}

file {"$play_frontend_home rights":
      path => $play_application_path,
      ensure  => 'present',
      mode  => '0664',
      owner => $play_frontend_username,
      group => $play_frontend_username,
      recurse => true,
      require => [Exec['unzip play']]
}

file {"$play_application_path start rights":
    path => "${play_application_path}/start",
    owner => $play_frontend_username,
    group => $play_frontend_username,
    mode  => '0750',
    require => [File["$play_frontend_home rights"]]
}

service { "$play_frontend_username":
    ensure  => "running",
    enable  => "true",
    hasstatus => false,
    require => Add_init_script["$play_frontend_username"],
}

$mindmap_backend_username = "mindmap-backend"
$mindmap_backend_home = "/var/$mindmap_backend_username"
$freeplane_version = "1.2.21"
$mindmap_backend_artifact = "freeplane_bin-$freeplane_version"
$mindmap_backend_unzipped_foldername = "freeplane-$freeplane_version"
$mindmap_backend_application_path = "$mindmap_backend_home/current"
$mindmap_backend_start_script = "$mindmap_backend_application_path/freeplane.sh"

add_user { "$mindmap_backend_username":
    username => "$mindmap_backend_username",
    full_name => "Freeplane server",
    home => $mindmap_backend_home,
}

exec { 'unzip mindmap_backend':
    command => "rm -rf ${mindmap_backend_unzipped_foldername} && unzip ${mindmap_backend_artifact}.zip && sudo rm -rf $mindmap_backend_application_path && sudo mv ${mindmap_backend_unzipped_foldername} $mindmap_backend_application_path",
    cwd => "$stuff_folder/artifacts",
    require => [Package["packages"], Add_user["$mindmap_backend_username"]],
    #onlyif => "test -f $mindmap_backend_application_path/freeplane.sh"
}

file {"$mindmap_backend_application_path rights":
    path => "$mindmap_backend_application_path",
    ensure  => 'present',
    mode  => '0664',
    owner => $mindmap_backend_username,
    group => $mindmap_backend_username,
    recurse => true,
    require => [Exec['unzip mindmap_backend']]
}

#workaround for https://github.com/Docear/HTW-Frontend/issues/136
exec { 'correct line endings for freeplane.sh':
    command => "fromdos $mindmap_backend_start_script",
    cwd => "$mindmap_backend_application_path",
    require => [Package["tofrodos"], Exec['unzip mindmap_backend']],
  #onlyif => "test -f $mindmap_backend_application_path/freeplane.sh"
}
package { "tofrodos":
    ensure => present,
    require => Exec['apt-get-update'],
}

file {"$mindmap_backend_application_path start rights":
    path => "$mindmap_backend_start_script",
    ensure  => 'present',
    owner => $mindmap_backend_username,
    group => $mindmap_backend_username,
    mode  => '0750',
    require => [File["$mindmap_backend_application_path rights"], Exec['correct line endings for freeplane.sh']]
}

file {"mindmap-backend-log-folder":
  ensure  => 'directory',
  path => "/var/log/mindmap-backend/",
  owner => $mindmap_backend_username,
  group => $mindmap_backend_username,
  mode  => '0750',
}

add_init_script {"$mindmap_backend_username":
    name => "$mindmap_backend_username",
    application_path => $mindmap_backend_application_path,
    start_command => "xvfb-run ${mindmap_backend_application_path}/freeplane.sh",
    user => "$mindmap_backend_username",
    group => "$mindmap_backend_username",
    pid_file => "$mindmap_backend_application_path/RUNNING_PID",
    current_working_dir => "$mindmap_backend_application_path",
    require => [File["mindmap-backend-log-folder"], File["$mindmap_backend_application_path start rights"]]
}

service { "$mindmap_backend_username":
  ensure => "running",
  enable  => "true",
  hasstatus => false,
  require => Add_init_script["$mindmap_backend_username"]
}
    #-L: Tell screen to turn on automatic output logging for the windows.
    #-d -m detach session, option for startup scripts
    #screen -L -d -m xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" bash freeplane.sh




#FIREWALL
package { "iptables":
    ensure => "installed",
    require => Exec['apt-get-update'],
}

class firewall {
  package { "shorewall":
    ensure => present,
    require => Package["iptables"],
  }

  exec { "safe-restart-shorewall ":
    command => "shorewall safe-restart",
    refreshonly => true,
  }

  file { "shorewall-policy ":
      path    => "/etc/shorewall/policy",
      content => template("$stuff_folder/puppet/manifests/shorewall/policy.erb"),
      require  => Package["shorewall"]
  }
  file { "shorewall-interfaces ":
      path    => "/etc/shorewall/interfaces",
      content => template("$stuff_folder/puppet/manifests/shorewall/interfaces.erb"),
      require  => Package["shorewall"]
  }
  file { "shorewall-zones ":
      path    => "/etc/shorewall/zones",
      content => template("$stuff_folder/puppet/manifests/shorewall/zones.erb"),
      require  => Package["shorewall"]
  }
  file { "shorewall-rules ":
      path    => "/etc/shorewall/rules",
      content => template("$stuff_folder/puppet/manifests/shorewall/rules.erb"),
      require  => Package["shorewall"]
  }

  service { "shorewall":
    ensure => running,
    require => [Package["shorewall"], File["shorewall-policy"], File["shorewall-interfaces"], File["shorewall-zones"], File["shorewall-rules"]]
  }
}