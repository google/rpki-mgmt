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

class configs {
  # Place the puppet config and default puppet files.
  file { '/etc/default/puppet':
    source => "$::puppet_files_infra/files/puppet/default-puppet",
    ensure => 'file',
  }
  file { '/etc/puppet/puppet.conf':
    source => 'puppet:///files/puppet.conf',
    ensure => 'file',
  }
  # Syslog clients get a client config.
  if $syslog_servers[$hostname] != 1 {
    file { '/etc/syslog-ng/syslog-ng.conf':
      source => "$::puppet_files_infra/files/puppet/syslog-client.conf",
      ensure => 'file',
      mode => '0644',
      owner => 'root',
      group => 'root',
      notify => Service['syslog-ng'],
    }
  }
  # Syslog servers get a server config.
  # For pub servers ensure a copy of the rsyncd.conf template exists.
  if $rpki_pub_servers[$hostname] == 1 {
    file { '/etc/default/rsync':
      source => "$::puppet:_files_infra/files/puppet/default-rsync",
      ensure => 'file',
      mode => '0644',
      owner => 'root',
      group => 'root',
    }
    file { '/etc/rsyncd.conf.templ':
      source => "$::puppet_files_infra/files/puppet/rsyncd.conf",
      ensure => 'file',
      mode => '0644',
      owner => 'root',
      group => 'root',
    }
  }
}
