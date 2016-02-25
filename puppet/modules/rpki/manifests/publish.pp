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
  $baseDir   = $::rpki::params::baseDir,
  $logServer = $::rpki::params::logServer,
  ) inherits ::rpki::params
{

  package { 'rsync':
    ensure => 'installed',
  } ->
  file { '/etc/rsyncd.conf.templ':
    source => "puppet:///modules/rpki/rsyncd.conf",
    ensure => 'file',
    mode => '0644',
    owner => 'root',
    group => 'root',
  } ->
  file_line { 'enable rsync':
    ensure => present,
    match  => '^#?RSYNC_ENABLE=',
    line   => 'RSYNC_ENABLE=true',
    path   => '/etc/default/rsync',
    notify => Service["rsync"],
  } ->
  service { 'rsync':
    ensure => 'running',
    enable => 'true',
    require => Package['rsync'],
  }

}
