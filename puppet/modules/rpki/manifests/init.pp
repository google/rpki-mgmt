# Copyright 2014 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class rpki(
  $baseDir   = $::rpki::params::baseDir,
  $logServer = $::rpki::params::logServer,
  
  # ssh
  $sshRestrictSource = $::rpki::params::sshRestrictSource,
  $sshPort = $::rpki::params::sshPort,
  $sshUnrestrictedPort = $::rpki::params::sshUnrestrictedPort,

  # log server
  $roleLogServer = $::rpki::params::roleLogServer,
  $logPort = $::rpki::params::logPort,

  # publication server
  $rolePublicationServer = $::rpki::params::rolePublicationServer,
  $rsyncPort = $::rpki::params::rsyncPort,
  $publicationBase = $::rpki::params::publicationBase,
  $publicationName = $::rpki::params::publicationName,

  # puppet server
  $rolePuppetServer = $::rpki::params::rolePuppetServer,
  $puppetPort = $::rpki::params::puppetPort,

  # rpki CA
  $roleRPKI_CA = $::rpki::params::roleRPKI_CA,
  $rpkiCAport = $::rpki::params::rpkiCAport,

  # rpki RP
  $roleRPKI_RP = $::rpki::params::roleRPKI_RP,
  $rpkiRPport = $::rpki::params::rpkiRPport,
  
  ) inherits ::rpki::params {

  # This will run apt-update before any package is installed, which
  # is needed when a new repo is added.
  #
  # Unfortunately, it seems to be run every time puppet runs, so
  # that needs to be figured out at come point
  #
  # currently disabled, since we're not adding the rpki.net repo (yet)
  #
  #exec { 'apt-update':
  #  command => '/usr/bin/apt-get update',
  #  #refreshonly => true,
  #}
  #
  # do apt update before any package get installed
  #Exec["apt-update"] -> Package <| |>

  anchor { 'rpki::begin': }
  anchor { 'rpki::end': }
  Anchor['rpki::begin'] ->
    Class['rpki::install'] ->
    Class['rpki::config'] ->
    Class['rpki::service'] ->
  Anchor['rpki::end']

  include rpki::install
  include rpki::config
  include rpki::service
}

# ---------------------------------------------------------------------
# Roles
# ---------------------------------------------------------------------

class rpki::role::pub_server {

  include rpki::profile::client

  class { 'rpki::iptables':
    rolePublicationServer => true,
    sshRestrictSource => $ssh_client_range,
    sshUnrestrictedPort => $ssh_unrestricted_port,
  }

  # publish rpki data for the world
  file { ['/srv/rsync/', '/srv/rsync/rpki/']:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => 0755,
  }
  class { 'rpki::publish':
    moduleName => 'rpki',
    modulePath => '/srv/rsync/rpki',
    moduleDescription => "$::hostname $rsync_module_description",
    moduleSource => "${ca_server}::rpki/",
    require => File['/srv/rsync/rpki'],
  }
}

# ------------------------------------

class rpki::role::log_server {

  include rpki::profile::common

  # configure puppet server
  class { 'rpki::puppet_config':
     puppetServer => $puppet_server,
  }

  class { 'rpki::iptables':
    roleLogServer => true,
    sshRestrictSource => $ssh_client_range,
    sshUnrestrictedPort => $ssh_unrestricted_port,
  }
  class { 'rpki::log_server':
  }
}

# ------------------------------------

class rpki::role::puppet_master {
  include rpki::profile::client

  class { 'rpki::iptables':
    rolePuppetServer => true,
    puppetClients => $puppet_client_range,
    sshRestrictSource => $ssh_client_range,
    sshUnrestrictedPort => $ssh_unrestricted_port,
  }

  class { 'rpki::puppet_master':
    gitCron_infraVerbose => 'y',
  } ->
  service { 'puppetmaster':
    ensure => 'running',
    enable => 'true',
    require => Package['puppetmaster'],
    hasrestart => true,
  }
}

# ------------------------------------

class rpki::role::rpki_master {
  include rpki::profile::client

  class { 'rpki::iptables':

    sshRestrictSource => $ssh_client_range,
    sshUnrestrictedPort => $ssh_unrestricted_port,

    # certificate master
    roleRPKI_CA => true,

    # publishing rpki data
    rolePublicationServer => true,
    # but only to these clients
    rsyncClients => $publication_servers,
  }

  # publish rpki data for publication servers
  file { ['/usr/share/rpki', '/usr/share/rpki/publication']:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => 0755,
  }

  class { 'rpki::publish':
    moduleName => 'rpki',
    modulePath => '/usr/share/rpki/publication',
    moduleDescription => "$::hostname $rsync_module_description",
    require => File['/usr/share/rpki/publication'],
  }

  package { 'exim4':
    ensure => 'installed',
  }

  include rpki::ca
}

# ---------------------------------------------------------------------
# Profiles
# ---------------------------------------------------------------------
class rpki::profile::common {
  include stdlib

  # set up users, etc
  class { "rpki_common_config": }

  # install/config common packages
  include rpki

  # setup syslog CA
  file { '/etc/syslog-ng/ca.d/':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0644',
    require => Package[ 'syslog-ng' ],
  }

  file { '/etc/syslog-ng/ca.d/ca.pem':
    ensure => present,
    source => '/var/lib/puppet/ssl/certs/ca.pem',
    require => File['/etc/syslog-ng/ca.d/'],
  }

  $caHash_line = generate ("/usr/bin/openssl",  "x509", "-noout", "-hash", "-in", "/var/lib/puppet/ssl/certs/ca.pem")
  $caHash = chomp($caHash_line)

  file { "/etc/syslog-ng/ca.d/$caHash.0":
    ensure => link,
    target => '/etc/syslog-ng/ca.d/ca.pem',
    require => File['/etc/syslog-ng/ca.d/'],
    notify => Service['syslog-ng'],
  }

}

# ------------------------------------

class rpki::profile::client(
  $logServer = $syslog_servers,
  $puppetServer = $puppet_server,
) {
  include rpki::profile::common

  # configure puppet server
  class { "rpki::puppet_config":
     puppetServer => $puppetServer,
  }

  # set up log destination
  class { "rpki::log_client":
    logServer => $logServer,
  }
}
