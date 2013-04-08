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
class apache($htpasswd_file_path = "/etc/apache2/.htpasswd") {
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
      require  => Package["apache2"],
      replace => false,
  }
  file { "ssl-server-key ":
      path    => "/etc/ssl/private/server.key",
      content => template("$stuff_folder/puppet/manifests/ssl/new.cert.key.erb"),
      require  => Package["apache2"],
      replace => false,
  }

  file { "apache htpasswd":
      path => "$htpasswd_file_path",
      content => file("$stuff_folder/puppet/manifests/htpasswd"),
      require => Package["apache2"],
  }

  file { "apache-conf":
      path    => "/etc/apache2/sites-available/default",
      content => template("$stuff_folder/puppet/manifests/apache-virtual-host.erb"),
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

define add_init_script($name, $application_path, $start_command, $user, $group, $pid_file, $current_working_dir, $unzipped_foldername) {

  file {"/etc/init.d/$name":
      content => template("$stuff_folder/puppet/manifests/init-with-pid.erb"),
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
  $redeploy_name= "$name-redeploy"

  file {"/etc/init.d/$redeploy_name":
      content => template("$stuff_folder/puppet/manifests/redeploy-daemon.erb"),
      ensure => present,
      group => "root",
      owner => "root",
      mode => 750,
  }

  exec {"activate /etc/init.d/$redeploy_name":
      command => "update-rc.d $redeploy_name defaults",
      require => [File["/etc/init.d/$redeploy_name"], Package["inotify-tools"]],
      notify => Service["$redeploy_name"],
  }

  service { "$redeploy_name":
      ensure => "running",
      enable  => "true",
      hasstatus => false,
  }
}

add_init_script {"$play_frontend_username":
  name => "$play_frontend_username",
  application_path => $play_application_path,
  start_command => "$play_application_path/start -Dconfig.resource=$play_config_resource -Dlogger.resource=prod-logger.xml -Dhttp.port=9000 -Dhttp.address=127.0.0.1 -Ddb.default.url=jdbc:h2:file:/tmp/play-frontend/h2/data",
  user => "$play_frontend_username",
  group => "$play_frontend_username",
  pid_file => "$play_application_path/RUNNING_PID",
  current_working_dir =>"$play_frontend_home",
  unzipped_foldername => $play_frontend_version,
  require => [Add_user[$play_frontend_username], File["$play_application_path start rights"]]
}

$play_frontend_artifact = "${play_frontend_artifact_folder}/${play_frontend_version}.zip"

add_redeploy_init_script {"play redeploy daemon":
  name => "${play_frontend_username}",
  artifact => $play_frontend_artifact,
}

file {"$play_frontend_home rights":
      path => $play_application_path,
      ensure  => 'directory',
      mode  => '0664',
      owner => $play_frontend_username,
      group => $play_frontend_username,
      recurse => true,
      require => [Package["packages"], Add_user["$play_frontend_username"]],
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
$freeplane_version = "1.2.21"
$mindmap_backend_artifact_folder = "/home/import/$mindmap_backend_username"
$mindmap_backend_artifact = "$mindmap_backend_artifact_folder/freeplane_bin-$freeplane_version.zip"
$mindmap_backend_unzipped_foldername = "freeplane-$freeplane_version"
$mindmap_backend_application_path = "$mindmap_backend_home/current"
$mindmap_backend_start_script = "$mindmap_backend_application_path/freeplane.sh"

add_user { "$mindmap_backend_username":
    username => "$mindmap_backend_username",
    full_name => "Freeplane server",
    home => $mindmap_backend_home,
}

file {"$mindmap_backend_application_path rights":
    path => "$mindmap_backend_application_path",
    ensure  => 'present',
    mode  => '0664',
    owner => $mindmap_backend_username,
    group => $mindmap_backend_username,
    recurse => true,
    require => [Package["packages"], Add_user["$mindmap_backend_username"]],
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
    start_command => "xvfb-run ${mindmap_backend_application_path}/freeplane.sh",
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


# add a line to a file
# http://projects.puppetlabs.com/projects/1/wiki/Simple_Text_Patterns
define line($file, $line, $ensure = 'present') {
    case $ensure {
        default : { err ( "unknown ensure value ${ensure}" ) }
        present: {
            exec { "/bin/echo '${line}' >> '${file}'":
                unless => "/bin/grep -qFx '${line}' '${file}'"
            }
        }
        absent: {
            exec { "/bin/grep -vFx '${line}' '${file}' | /usr/bin/tee '${file}' > /dev/null 2>&1":
              onlyif => "/bin/grep -qFx '${line}' '${file}'"
            }
        }
    }
}

# disable password promp for sudo users
line { "nopasswd-sudo":
    file => "/etc/sudoers",
    line => "%sudo ALL=(ALL) NOPASSWD: ALL",
}
# disable ssh login via password
line { "no-pass-login":
    file => "/etc/ssh/sshd_config",
    line => "PasswordAuthentication no",
}
# disable root ssh login
line { "no-root-ssh":
    file => "/etc/ssh/sshd_config",
    line => "PermitRootLogin no",
}
# 
line { "RSAAuthentication-ssh":
    file => "/etc/ssh/sshd_config",
    line => "RSAAuthentication yes",
}
# 
line { "PubkeyAuthentication-ssh":
    file => "/etc/ssh/sshd_config",
    line => "PubkeyAuthentication yes",
}
# 
line { "UsePAM-ssh":
    file => "/etc/ssh/sshd_config",
    line => "UsePAM no",
}
# 
line { "ChallengeResponseAuthentication-ssh":
    file => "/etc/ssh/sshd_config",
    line => "ChallengeResponseAuthentication no",
}
 
exec { 'reload-ssh':
  command => '/etc/init.d/ssh reload',
  require => [Line['no-pass-login'],Line['no-root-ssh'],Line['RSAAuthentication-ssh'],Line['PubkeyAuthentication-ssh'],Line['UsePAM-ssh'],Line['ChallengeResponseAuthentication-ssh']]
}

	
	

	
#Server Time NTP: http://articles.slicehost.com/2010/11/8/using-ntp-to-sync-time-on-debian
package { "ntp":
    ensure => present,
    require => Exec['apt-get-update'],
}
exec { 'set-correct-servertime':
    command => "/etc/init.d/ntp start",
    require => [Package["ntp"]],
}
