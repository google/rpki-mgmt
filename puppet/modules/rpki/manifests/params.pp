class rpki::params () {

  if $::osfamily == 'Debian' {

    $baseDir   = '/usr/local'
    $publicationBase = '/srv/rsync'
    $publicationName = 'rpki'
    $logServer = []

  } else {
    fail("Class['screech_owl::params']: Unsupported osfamily: ${::osfamily}")
  }

}
