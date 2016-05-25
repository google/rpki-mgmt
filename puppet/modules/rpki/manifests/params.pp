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
    # -- for git_cron script
    $gitCron_infraRepoDir = '/var/lib/rpki-mgmt'
    $gitCron_infraRepoName = 'rpki-mgmt.git'
    $gitCron_infraRepo = "$gitCron_infraRepoDir/$gitCron_infraRepoName"
    $gitCron_puppetInfraDir = '/etc/puppet'
    $gitCron_removeNotify = ''
    $gitCron_infraNotify = '/var/log/syslog'
    $gitCron_infraVerbose = ''

    # rpki CA
    $manageRPKI_CA = false
    $roleRPKI_CA = false
    $rpkiCAport = 80

    # rpki RP
    $roleRPKI_RP = false
    $rpkiRPport = 323
    $manageRcynic = false
    $rcynicBase = '/var/rcynic/data'

    case $::lsbmajdistrelease {
      '8': {
        $pupdeffile = '/etc/default/puppetmaster'
        $ipt_pkg = 'netfilter-persistent'
      }
      '7': {
        $pupdeffile = '/etc/default/puppet.conf'
        $ipt_pkg = 'iptables-persistent'
      }
      default: { fail("debian release $::lsbmajdistrelease not supported") }
    }

  } else {
    fail("Class['screech_owl::params']: Unsupported osfamily: ${::osfamily}")
  }

}
