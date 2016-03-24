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
  $gitCron_infraRepoDir = $::rpki::params::gitCron_infraRepoDir,
  $gitCron_infraRepoName = $::rpki::params::gitCron_infraRepoName,
  $gitCron_infraNotify = $::rpki::params::gitCron_infraNotify,
  $gitCron_infraVerbose = $::rpki::params::gitCron_infraVerbose,
)  inherits ::rpki::params
{
  $gitCron_infraRepo = "$gitCron_infraRepoDir/$gitCron_infraRepoName"

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
  # TODO: frequency will need to change once we expose the option for
  #       checking for changes in a local repo instead of pulling
  #       directly from github.
  cron { git_sync:
    command => '/usr/local/sbin/git_cron.sh > /tmp/git_cron.log 2>&1',
    ensure => 'present',
    user => 'root',
    hour => '3',
    minute => '15',
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
     # repo for pulling config
     "$gitCron_infraRepoDir", "$gitCron_infraRepo",
     ] :
      ensure => 'directory',
      owner => 'root',
      group => 'root',
      mode => 0750,
  }

}
