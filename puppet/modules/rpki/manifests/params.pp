class rpki::params () {

  if $::osfamily == 'Debian' {

    $baseDir   = '/usr/local'

    # client log destination
    $logServer = []

    # ssh
    $sshRestrictSource = ''
    $sshPort = 22
    $sshUnrestrictedPort = ''

    # log server
    $roleLogServer = false
    $logPort = 5140

    # publication server
    $rolePublicationServer = false
    $rsyncPort = 873
    $rsyncClients = []
    $publicationBase = '/srv/rsync'
    $publicationName = 'rpki'

    # puppet server
    $rolePuppetServer = false
    $puppetPort = 8140

    # rpki CA
    $manageRPKI_CA = false
    $roleRPKI_CA = false
    $rpkiCAport = 80

    # rpki RP
    $roleRPKI_RP = false
    $rpkiRPport = 323
    $manageRcynic = false
    $rcynicBase = '/var/rcynic/data'

  } else {
    fail("Class['screech_owl::params']: Unsupported osfamily: ${::osfamily}")
  }

}
