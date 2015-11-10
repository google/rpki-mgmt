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

class rpki::publish(
  $moduleName, $modulePath,
  $moduleDescription = "$moduleName",
  $moduleSource = '',
  ) inherits ::rpki::params
{

  package { 'rsync':
    ensure => 'installed',
  } ->
  file { '/etc/rsyncd.conf':
    content => template('rpki/rsyncd.conf.erb'),
    mode => '0644',
    owner => 'root',
    group => 'root',
    require => Package['rsync'],
  } ->
  file_line { 'enable rsync':
    ensure => present,
    match  => '^RSYNC_ENABLE=',
    line   => 'RSYNC_ENABLE=true',
    path   => '/etc/default/rsync',
    require => Package['rsync'],
    notify => Service["rsync"],
  } ->
  service { 'rsync':
    ensure => 'running',
    enable => 'true',
    require => Package['rsync'],
    hasrestart => true,
  }

  if $moduleSource != '' {
    file { '/usr/local/bin/puppet_pull.sh':
      source => "puppet:///modules/rpki/puppet_pull.sh",
      ensure => 'file',
      owner => 'root',
      group => 'root',
      mode => '0750',
    } ->
    cron { "pull data for $moduleName module":
      command => "/usr/local/bin/puppet_pull.sh $moduleSource $modulePath >> /tmp/puppet_pull.log 2>&1",
      ensure => 'present',
      user => 'root',
      minute => '*/5',
      require => File['/usr/local/bin/puppet_pull.sh'],
    }
  }

}
