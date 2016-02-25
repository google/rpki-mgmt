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

define rpki::puppet_master(
)
{
  package { 'git':
    ensure => 'installed',
  } ->
  file { "/usr/local/sbin/git_cron.sh":
    source  => "puppet:///modules/rpki/git_cron.sh",
    ensure => 'file',
    owner   => 'root',
    mode    => 0755,
  } ->
  cron { git_sync:
    command => '/usr/local/sbin/git_cron.sh > /tmp/git_cron.log 2>&1',
    ensure => 'present',
    user => 'root',
    require => File['/usr/local/sbin/git_cron.sh'],
  }

}
