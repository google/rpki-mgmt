#
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
# ---------------------------------------------------------------
#
# This layout uses the Role/Profile model from
#    http://www.craigdunn.org/2012/05/239/
#
# A node should have one role (e.g. webserver), and that role
# can include multiple profiles (e.g. apache, mysql, etc).
#
# "Roles are intended to be aggregator Puppet classes. Apply a
#  single role at the classification level. If more than one
#  role is being applied to a single node, perhaps it should be
#  a profile instead, or perhaps that combination of profiles
#  should be turned into a role."
#
# "Profiles are intended to be aggregator Puppet classes that
#  put together utility modules to construct site-meaningful
#  configurations. They deal with high-level abstractions and
#  glue them together. Multiple profiles may be deployed to a
#  single machine. Profiles are often the building blocks of
#  Roles."
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Globals
# ---------------------------------------------------------------

$rsync_module_description = 'RPKI Testbed Googlez'

# syslog servers that all clients will use 
$syslog_servers = [
                   'log-1.example.com',
                  ]

$puppet_server = 'puppet.example.com'

# where do publication servers get their data?
# TODO: handle multiple sources, distribute amongst pub servers
$ca_server = 'ca.example.com'

# publication servers
$publication_servers = [
                        'publish-1.example.com',
                        ]

# ip range for ssh access on port 22
$ssh_client_range = '0.0.0.0/0'

# ---------------------------------------------------------------
# Nodes
# ---------------------------------------------------------------

# ------------------------------------
# syslog servers
node 'log-1.example.com'
{
  include role::log_server
}

# ------------------------------------
# publication nodes
node 'publish-1.example.com'
{
  include role::pub_server
}

# ------------------------------------
node 'ca.example.com'
{
  include role::rpki_master
}

# ------------------------------------
node 'puppet.example.com'
{
  include role::puppet_master
}

# ------------------------------------
node "default" {
  include stdlib
  class { "common_config": }

  class { "rpki::puppet_config":
     puppetServer => $puppet_server,
  }
}

# ---------------------------------------------------------------------
# Roles
# ---------------------------------------------------------------------

class role::pub_server {

  include profile::client

  class { 'rpki::iptables':
    rolePublicationServer => true,
    sshRestrictSource => $ssh_client_range,
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

class role::log_server {

  include profile::common

  # configure puppet server
  class { 'rpki::puppet_config':
     puppetServer => $puppet_server,
  }

  class { 'rpki::iptables':
    roleLogServer => true,
    sshRestrictSource => $ssh_client_range,
  }
  class { 'rpki::log_server':
  }
}

# ------------------------------------

class role::puppet_master {
  include profile::client

  class { 'rpki::iptables':
    rolePuppetServer => true,
    sshRestrictSource => $ssh_client_range,
  }

  class { 'rpki::puppet_master':
    gitCron_infraRepo => '/root/rpki-mgmt.git',
    gitCron_infraNotify => '/tmp/git_cron.run',
    gitCron_infraVerbose => 'y',
  }
}

# ------------------------------------

class role::rpki_master {
  include profile::client

  class { 'rpki::iptables':

    sshRestrictSource => $ssh_client_range,

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

  include rpki::ca
}

# ---------------------------------------------------------------------
# Profiles
# ---------------------------------------------------------------------
class profile::common {
  include stdlib

  # set up users, etc
  class { "common_config": }

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

class profile::client(
  $logServer = $syslog_servers,
  $puppetServer = $puppet_server,
) {
  include profile::common

  # configure puppet server
  class { "rpki::puppet_config":
     puppetServer => $puppetServer,
  }

  # set up log destination
  class { "rpki::log_client":
    logServer => $logServer,
  }
}

# ---------------------------------------------------------------------
# Classes
# ---------------------------------------------------------------------

class common_config {
  # --- Users ---
  #
  # morrowc
  #
  user {'morrowc':
    ensure => 'present',
  }

  # rstory
  #
  user {'rstory':
    ensure => 'present',
    shell => '/bin/bash',
  }
}
