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