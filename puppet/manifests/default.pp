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

add_user { "play-frontend":
  username => "play-frontend",
  full_name => "play frontend server",
  home => "/var/play-frontend",
}