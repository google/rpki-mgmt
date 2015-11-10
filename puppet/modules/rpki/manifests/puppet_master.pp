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

class rpki::puppet_master(
  $gitCron_infraRepo = $::rpki::params::gitCron_infraRepo,
  $gitCron_infraNotify = $::rpki::params::gitCron_infraNotify,
  $gitCron_infraVerbose = $::rpki::params::gitCron_infraVerbose,
)  inherits ::rpki::params
{
  package { ['git', 'puppetmaster', 'puppet-lint']:
    ensure => 'installed',
  }
  file { "/usr/local/sbin/git_cron.sh":
    source  => "puppet:///modules/rpki/git_cron.sh",
    ensure => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => 0755,
    require => Package['puppetmaster'],
  }
  cron { git_sync:
    command => '/usr/local/sbin/git_cron.sh > /tmp/git_cron.log 2>&1',
    ensure => 'present',
    user => 'root',
    require => [ File['/usr/local/sbin/git_cron.sh'],
                 File['/etc/default/rpki-mgmt'], ],
  }

  file { '/etc/default/rpki-mgmt':
    content => template('rpki/rpki-mgmt-config.erb'),
    ensure => 'present',
    mode => 0644,
    owner => root,
    group => root,
  }

  file {
    [
     # mount directories for fileserver
     '/etc/puppet/mounts',
     '/etc/puppet/mounts/private', '/etc/puppet/mounts/public',
     # repo for pulling config
     '/srv/repo', '/srv/repo/rpki-mgmt',
     ] :
      ensure => 'directory',
      owner => 'root',
      group => 'root',
      mode => 0750,
  } ->
  ini_setting { 'puppet mount private host files':
    ensure => present,
    path   => '/etc/puppet/fileserver.conf',
    section => 'private',
    setting => 'path',
    key_val_separator => ' ',
    value   => "/etc/puppet/mounts/private/%H",
  }
  ini_setting { 'puppet mount public files':
    ensure => present,
    path   => '/etc/puppet/fileserver.conf',
    section => 'public',
    setting => 'path',
    key_val_separator => ' ',
    value   => "/etc/puppet/mounts/public",
  }
  ini_setting { 'remove default files config':
    ensure => absent,
    path   => '/etc/puppet/fileserver.conf',
    section => 'files',
    setting => 'path',
    key_val_separator => ' ',
  }

}
