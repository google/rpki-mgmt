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

class rpki::iptables(
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
  $rsyncClients = $::rpki::params::rsyncClients,
  $publicationBase = $::rpki::params::publicationBase,
  $publicationName = $::rpki::params::publicationName,

  # puppet server
  $rolePuppetServer = $::rpki::params::rolePuppetServer,
  $puppetPort = $::rpki::params::puppetPort,
  $puppetClients = $::rpki::params::puppetClients,

  # rpki CA
  $roleRPKI_CA = $::rpki::params::roleRPKI_CA,
  $rpkiCAport = $::rpki::params::rpkiCAport,

  # rpki RP
  $roleRPKI_RP = $::rpki::params::roleRPKI_RP,
  $rpkiRPport = $::rpki::params::rpkiRPport,
  
  ) inherits ::rpki::params {

<<<<<<< HEAD
  file { '/etc/iptables':
    ensure => 'directory',
    mode => 0750,
    owner => 'root',
    group => 'root',
  }

=======
>>>>>>> parent of 63ebd50... Iptables config was failing to install:
  file { '/etc/iptables/rules.v4':
    content => template('rpki/iptables.v4.erb'),
    ensure => 'present',
    mode => '0644',
    owner => 'root',
    group => 'root',
    notify => Service["$rpki::params::ipt_pkg"],
  }

  }
