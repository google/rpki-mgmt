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

class rpki::log_server() inherits ::rpki::params
{
  $sslKey = "/etc/syslog-ng/ca.d/$fqdn.key"
  $sslCert = "/etc/syslog-ng/ca.d/$fqdn.pem"

  file { "$sslKey":
    ensure => present,
    source => "/var/lib/puppet/ssl/private_keys/$fqdn.pem",
    owner => root,
    group => root,
    mode => 0600,
    require => File['/etc/syslog-ng/ca.d/'],
  }
  file { "$sslCert":
    ensure => present,
    source => "/var/lib/puppet/ssl/certs/$fqdn.pem",
    owner => root,
    group => root,
    mode => 0600,
    require => File['/etc/syslog-ng/ca.d/'],
  }

  file { '/etc/syslog-ng/syslog-ng.conf':
    content => template('rpki/syslog-server.conf.erb'),
    ensure => 'present',
    mode => '0644',
    owner => 'root',
    group => 'root',
    require => [ File["$sslKey"], File["$sslCert"] ],
    notify => Service['syslog-ng'],
  }
}
