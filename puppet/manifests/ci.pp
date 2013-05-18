notify{"using the ci.pp": }

Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", ] }

import "common.pp"

import "users/*.pp"

#class jenkins() {
#
#  exec { "setup jenkins repository key for package tools":
#      command => "http://pkg.jenkins-ci.org/debian/",
#      refreshonly => true,
#  }
#}

#this approaches didn't worked:
#using http://pkg.jenkins-ci.org/debian/
#using https://wiki.jenkins-ci.org/display/JENKINS/Puppet
#beware of bug http://projects.puppetlabs.com/issues/13858


class jenkins {
  package { "daemon":
    ensure => "present"
  }

  $debName = "jenkins_1.514_all.deb"

  exec { "get deb jenkins":
    command => "wget -c http://pkg.jenkins-ci.org/debian/binary/$debName",
    cwd => "/tmp",
    creates  => "/tmp/$debName",
    onlyif => "test ! -f tmp/$debName",
    require => Package["daemon"]
  }

  exec { "install deb":
    command => "dpkg -i $debName",
    cwd => "/tmp",
    require => Exec["get deb jenkins"]
  }

  $jenkinsConfigFile = "/etc/default/jenkins"

  file {"$jenkinsConfigFile":
      content => template("$manifest_folder/jenkins.conf.erb"),
      ensure => present,
      group => "root",
      owner => "root",
      mode => 644,
      require => Exec["install deb"],
      notify => Service["jenkins"]
  }

  service { "jenkins":
    ensure => running,
  }
}

include jenkins