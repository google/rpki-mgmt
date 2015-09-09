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

class services {
  service { 'puppet':
    ensure => "running",
    enable => 'true',
    require => Package['puppet'],
  }
  service { 'syslog-ng':
    ensure => "running",
    enable => 'true',
    require => Package['syslog-ng'],
  }
  # If this is a publication server, make sure rsync is running.
  if $rpki_pub_servers[$hostname] == 1 {
    service { 'rsync':
      ensure => 'running',
      enable => 'true',
      require => Package['rsync'],
    }
  }
}
