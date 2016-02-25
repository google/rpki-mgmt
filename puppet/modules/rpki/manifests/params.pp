class rpki::params () {

  if $::osfamily == 'Debian' {

    $baseDir   = '/usr/local'
    $logServer = []

  } else {
    fail("Class['screech_owl::params']: Unsupported osfamily: ${::osfamily}")
  }

}
