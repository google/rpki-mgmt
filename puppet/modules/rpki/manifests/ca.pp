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

class rpki::ca(
  $manageRcynic = $rpki::params::manageRcynic,
  $manageCA = $rpki::params::manageRPKI_CA,
  $rcynicBase = $rpki::params::rcynicBase,
)
{
  rpki::rpki_repo { 'rpki repo ca': }

  if $manageCA {
    package { 'rpki-ca':
      require => [ File['/etc/apt/sources.list.d/rpki.list'], Exec['add rpki GPG key'] ],
      ensure => 'latest',
    }
  }

  #--------------------------------------------------------------------
  # config rcynic
  #  - do we need this? can we just use defaults?
  #--------------------------------------------------------------------
  # options we aren't currently managing:
  #   rsync-program           = /usr/bin/rsync
  #   jitter                  = 600
  #   max-parallel-fetches    = 8
  #   use-syslog              = true
  #   log-level               = log_usage_err
  
  if $manageRcynic {
    ini_setting { 'rcynic trust-anchor-directory':
      ensure => 'present',
      path   => '/etc/rcynic.conf',
      section => 'rcynic',
      setting => 'trust-anchor-directory',
      value   => "/etc/rpki/trust-anchors",
    } 
    ini_setting { 'rcynic authenticated':
      ensure => 'present',
      path   => '/etc/rcynic.conf',
      section => 'rcynic',
      setting => 'authenticated',
      value   => "$rcynicBase/authenticated",
    } 
    ini_setting { 'rcynic unauthenticated':
      ensure => 'present',
      path   => '/etc/rcynic.conf',
      section => 'rcynic',
      setting => 'unauthenticated',
      value   => "$rcynicBase/unauthenticated",
    } 
    ini_setting { 'rcynic xml-summary':
      ensure => 'present',
      path   => '/etc/rcynic.conf',
      section => 'rcynic',
      setting => 'xml-summary',
      value   => "$rcynicBase/rcynic.xml",
    } 
  }
}
