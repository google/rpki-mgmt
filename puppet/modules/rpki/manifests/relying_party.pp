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

class rpki::relying_party(
)
{
  exec {'get rpki.net GPG key':
    command => "/usr/bin/wget -q -O /etc/apt/trusted.gpg.d/rpki-apt-gpg-key.asc http://download.rpki.net/APT/apt-gpg-key.asc",
    creates => "/etc/apt/trusted.gpg.d/rpki-apt-gpg-key.asc",
  }
  file {'/etc/apt/trusted.gpg.d/rpki-apt-gpg-key.asc':
    mode => 0644,
    owner => 'root',
    group => 'root',
    require => Exec["get rpki.net GPG key"],
  }
  exec { 'add rpki GPG key':
    command => '/usr/bin/apt-key add /etc/apt/trusted.gpg.d/rpki-apt-gpg-key.asc',
    require => File['/etc/apt/trusted.gpg.d/rpki-apt-gpg-key.asc'],
    refreshonly => true,
  }

  exec{'get rpki.net APT repo':
    command => "/usr/bin/wget -q -O /etc/apt/sources.list.d/rpki.list http://download.rpki.net/APT/rpki.$::lsbdistcodename.list",
    creates => "/etc/apt/sources.list.d/rpki.list",
  }
  file{'/etc/apt/sources.list.d/rpki.list':
    mode => 0644,
    owner => 'root',
    group => 'root',
    require => Exec["get rpki.net APT repo"],
  }

  package { 'rpki-rp':
     require => [ File['/etc/apt/sources.list.d/rpki.list'], Exec['add rpki GPG key'] ],
     ensure => 'latest',
  }

}
