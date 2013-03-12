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
      require => [Group["$username"], File["$home"]]
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

  file { "$home":
      ensure => "directory",
  }

  group { $username:
      ensure => "present",
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
      content => template("/vagrant/puppet/manifests/apache-virtual-host.erb"),
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

define add_init_script($name, $application_path, $start_command, $user, $group, $pid_file) {

  file {"/etc/init.d/$name":
      content => template("/vagrant/puppet/manifests/init-with-pid.erb"),
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
  require => [Add_user[$play_frontend_username], File["$play_application_path start rights"]]
}

exec { 'unzip play':
      command => "rm -rf ${play_frontend_version} && unzip ${play_frontend_version}.zip && sudo rm -rf $play_application_path && sudo mv ${play_frontend_version} $play_application_path",
      cwd => "/vagrant/artifacts",
      require => [],
      onlyif => "test -f $play_application_path/start"
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
    ensure  => 'present',
    owner => $play_frontend_username,
    group => $play_frontend_username,
    mode  => '0750',
    require => [File["$play_frontend_home rights"]]
}

service { "$play_frontend_username":
    ensure  => "running",
    enable  => "true",
    require => Add_init_script["$play_frontend_username"],
}