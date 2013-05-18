notify{"using the ci.pp": }

Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/", "/usr/local/bin", ] }

import "common.pp"

import "users/*.pp"