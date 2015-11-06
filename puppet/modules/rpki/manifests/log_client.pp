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

class rpki::log_client(
  $logServer,
  ) inherits ::rpki::params {

  file { '/etc/syslog-ng/syslog-ng.conf':
    content => template('rpki/syslog-client.conf.erb'),
    ensure => 'present',
    mode => '0644',
    owner => 'root',
    group => 'root',
    notify => Service['syslog-ng'],
  }

  file { '/etc/syslog-ng/ca.d/':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0644',
  }

  file { '/etc/syslog-ng/ca.pem':
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
