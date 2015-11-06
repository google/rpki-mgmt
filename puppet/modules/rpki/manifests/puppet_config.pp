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
class rpki::puppet_config(
  $puppetServer ) 
{
  package { 'puppet':
    ensure => 'installed',
  } ->
  file_line { 'start puppet on boot': # xxx: debian-ism
    ensure => present,
    match  => '^#?START=',
    line   => 'START=true',
    path   => '/etc/default/puppet',
    notify => Service["puppet"],
  } ->
  ini_setting { 'puppet server':
    ensure => 'present',
    path   => '/etc/puppet/puppet.conf',
    section => 'main',
    setting => 'server',
    value   => "$puppetServer",
  } ->
  file { '/usr/local/bin/puppet_cleanup.sh':
    source => "puppet:///modules/rpki/puppet_cleanup.sh",
    ensure => 'file',
    owner => 'root',
    group => 'root',
    mode => '0750',
  }

  # Run puppet cleanup, make sure puppet is not hung, restart if it has.
  cron { puppet_cleanup:
    command => "/usr/local/bin/puppet_cleanup.sh >> /tmp/puppet_cleanup.log 2>&1",
    ensure => 'present',
    user => 'root',
    minute => 0,
    require => File['/usr/local/bin/puppet_cleanup.sh'],
  }

}
