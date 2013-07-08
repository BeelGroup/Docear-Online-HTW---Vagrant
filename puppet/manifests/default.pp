notify{"The deploy_environment is: ${deploy_environment}": }

Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", ] }

import "common.pp"

import "mongodb.pp"
include mongodb

#http://projects.puppetlabs.com/projects/1/wiki/Debian_Apache2_Recipe_Patterns
class apache($htpasswd_file_path = "/etc/apache2/.htpasswd") {
  package { "apache2":
    ensure => present,
    require => Exec['apt-get-update'],
  }

  file {"/var/log/apache2":
    ensure => "directory",
    group => "root",
    owner => "root"
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
      content => template("$stuff_folder/manifests/ssl/new.cert.cert.erb"),
      require  => Package["apache2"],
      replace => false,
  }
  file { "ssl-server-key ":
      path    => "/etc/ssl/private/server.key",
      content => template("$stuff_folder/manifests/ssl/new.cert.key.erb"),
      require  => Package["apache2"],
      replace => false,
  }

  file { "apache htpasswd":
      path => "$htpasswd_file_path",
      content => file("$stuff_folder/manifests/htpasswd"),
      require => Package["apache2"],
  }

  $domain = $deploy_environment ? {
      'dev' =>  "localhost",
      'staging' => "staging.my.docear.org",
      'prod' => "my.docear.org"
  }

  file { "apache-conf":
      path    => "/etc/apache2/sites-available/default",
      content => template("$stuff_folder/manifests/apache-virtual-host.erb"),
      require  => [Package["apache2"], Module["proxy"], Module["proxy_http"], Module["proxy_balancer"], Module["ssl"], Module["headers"], File["ssl-server-crt "], File["ssl-server-key "], File["apache htpasswd"]],
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
$play_frontend_artifact_folder = "/home/import/$play_frontend_username"
$play_frontend_home = "/var/$play_frontend_username"
$play_application_path = "$play_frontend_home/current"
$play_config_resource = $deploy_environment ? {
    'dev' =>  "showtime.conf",
    'staging' => "staging.conf",
    'prod' => "prod.conf"
}
$play_frontend_version = "docear-frontend-0.1-SNAPSHOT"

add_user { "$play_frontend_username":
  username => "$play_frontend_username",
  full_name => "play frontend server",
  home => $play_frontend_home,
}

define add_init_script($name, $application_path, $start_command, $user, $group, $pid_file, $current_working_dir, $unzipped_foldername) {

  file {"/etc/init.d/$name":
      content => template("$stuff_folder/manifests/init-with-pid.erb"),
      ensure => present,
      group => "root",
      owner => "root",
      mode => 750,
  }

  exec {"activate /etc/init.d/$name":
      command => "update-rc.d $name defaults",
      require => File["/etc/init.d/$name"]
  }
}

package {"inotify-tools":
    require => Exec['apt-get-update'],
}

define add_redeploy_init_script($name, $artifact) {
  $redeploy_name="$name-redeploy"

  file {"/etc/init.d/$redeploy_name":
      content => template("$stuff_folder/manifests/redeploy-daemon.erb"),
      ensure => present,
      group => "root",
      owner => "root",
      mode => 750,
      require => Package["inotify-tools"],
  }

  exec {"activate /etc/init.d/$redeploy_name":
      require => File["/etc/init.d/$redeploy_name"],
      command => "update-rc.d $redeploy_name defaults",
      notify => Service["$redeploy_name"],
  }

  service { "$redeploy_name":
      ensure => "running",
      enable  => "true",
      hasstatus => false,
      require => Exec["activate /etc/init.d/$redeploy_name"]
  }
}

add_init_script {"$play_frontend_username":
  name => "$play_frontend_username",
  application_path => $play_application_path,
  start_command => "$play_application_path/start -Xms128M -Xmx512m -Dconfig.resource=$play_config_resource -Dlogger.resource=prod-logger.xml -Dhttp.port=9000 -Dhttp.address=127.0.0.1 -Ddb.default.url=jdbc:h2:file:/tmp/play-frontend/h2/data",
  user => "$play_frontend_username",
  group => "$play_frontend_username",
  pid_file => "$play_application_path/RUNNING_PID",
  current_working_dir =>"$play_frontend_home",
  unzipped_foldername => $play_frontend_version,
  require => [Add_user[$play_frontend_username], File["$play_application_path start rights"]]
}

$play_frontend_artifact = "${play_frontend_artifact_folder}/${play_frontend_version}.zip"

file {"$play_frontend_artifact_folder":
  ensure => "directory",
  group => "import",
  owner => "import",
  mode => 770,
  require => Add_user["import"]
}

add_redeploy_init_script {"play redeploy daemon":
  name => "${play_frontend_username}",
  artifact => $play_frontend_artifact,
}

file {"$play_frontend_home rights":
      path => $play_application_path,
      ensure  => 'directory',
      mode  => '0660',
      owner => $play_frontend_username,
      group => $play_frontend_username,
      recurse => true,
      require => [Package["packages"], Add_user["$play_frontend_username"], File["$play_frontend_artifact_folder"]],
}

file {"$play_application_path start rights":
    path => "${play_application_path}/start",
    owner => $play_frontend_username,
    group => $play_frontend_username,
    mode  => '0750',
    require => [File["$play_frontend_home rights"]]
}

file {"$play_frontend_username-log-folder":
    ensure  => 'directory',
    path => "/var/log/$play_frontend_username/",
    owner => $play_frontend_username,
    group => $play_frontend_username,
    mode  => '0770',
    require => Add_user[$play_frontend_username],
}

$mindmap_backend_username = "mindmap-backend"
$mindmap_backend_home = "/var/$mindmap_backend_username"
$mindmap_backend_artifact_folder = "/home/import/$mindmap_backend_username"
$mindmap_backend_artifact = "$mindmap_backend_artifact_folder/freeplane_server.zip"
$mindmap_backend_unzipped_foldername = "freeplane"
$mindmap_backend_application_path = "$mindmap_backend_home/current"
$mindmap_backend_start_script = "$mindmap_backend_application_path/freeplane-server.sh"

add_user { "$mindmap_backend_username":
    username => "$mindmap_backend_username",
    full_name => "Freeplane server",
    home => $mindmap_backend_home,
}

file {"$mindmap_backend_artifact_folder":
  ensure => "directory",
  group => "import",
  owner => "import",
  mode => 770,
  require => Add_user["import"]
}

file {"$mindmap_backend_application_path rights":
    path => "$mindmap_backend_application_path",
    ensure  => 'present',
    mode  => '0764',
    owner => $mindmap_backend_username,
    group => $mindmap_backend_username,
    recurse => true,
    require => [Package["packages"], Add_user["$mindmap_backend_username"], File["$mindmap_backend_artifact_folder"]],
}

file {"mindmap-backend-log-folder":
  ensure  => 'directory',
  path => "/var/log/mindmap-backend/",
  owner => $mindmap_backend_username,
  group => $mindmap_backend_username,
  mode  => '0770',
}

add_init_script {"$mindmap_backend_username":
    name => "$mindmap_backend_username",
    application_path => $mindmap_backend_application_path,
    start_command => "xvfb-run ${mindmap_backend_application_path}/freeplane-server.sh",
    user => "$mindmap_backend_username",
    group => "$mindmap_backend_username",
    pid_file => "$mindmap_backend_application_path/RUNNING_PID",
    current_working_dir => "$mindmap_backend_application_path",
    unzipped_foldername => $mindmap_backend_unzipped_foldername,
    require => [File["mindmap-backend-log-folder"]]
}

add_redeploy_init_script {"$mindmap_backend_username redeploy daemon":
    name => "$mindmap_backend_username",
    artifact => $mindmap_backend_artifact,
}
	
	
	
import "users/*.pp"

if $deploy_environment == 'dev' {
    notify{ "deploy of services": }

    exec { "service $mindmap_backend_username next":
        require => Add_init_script["$mindmap_backend_username"],
    }

    exec { "service $play_frontend_username next":
      require => Add_init_script["$play_frontend_username"],
    }
} else {
    notify{"no autostart of services in the current deploy environment: ${deploy_environment}": }
}