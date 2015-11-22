# Define: sysctl
#
# Manage sysctl variable values.
#
# Parameters:
#  $value:
#    The value for the sysctl parameter. Mandatory, unless $ensure is 'absent'.
#  $ensure:
#    Whether the variable's value should be 'present' or 'absent'.
#    Defaults to 'present'.
#
# Sample Usage :
#  sysctl { 'net.ipv6.bindv6only':
#    value   => '1',
#    comment => 'Some comment',
#  }
#
define sysctl (
  $ensure  = undef,
  $key     = $title,
  $value   = undef,
  $comment = undef,
) {
  # Parent purged directory
  require sysctl::base

  # The permanent change
  file { "/etc/sysctl.d/${title}.conf":
    ensure  => $ensure,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => "# ${comment}\n${key} = ${value}\n",
  }

  if $ensure != 'absent' {
    # The immediate change + re-check on each run "just in case"
    exec { "sysctl-${title}":
      command => "/sbin/sysctl -w ${key}=\"${value}\"",
      unless  => "/sbin/sysctl -n ${key} | /bin/grep -q -e '^${value}\$'",
    }
    # For the few original values from the main file
    exec { "update-sysctl.conf-${title}":
      command => "sed -i -e 's/${key} =.*/${key} = ${value}/' /etc/sysctl.conf",
      unless  => "/bin/bash -c \"! egrep '^${key} =' /etc/sysctl.conf || egrep '^${key} = ${value}\$' /etc/sysctl.conf\"",
      path    => [ '/usr/sbin', '/sbin', '/usr/bin', '/bin' ],
    }
  }
}
