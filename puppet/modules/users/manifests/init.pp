# $Id$
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
# Manage administrative users on rpki-testing systems.
class users {

  # morrowc
  #
  user {'morrowc':
    ensure => 'present',
    # morrowc's ssh content is managed by GCE
  }

  # rstory
  #
  user {'rstory':
    ensure => 'present',
    managehome => 'true',
  }
  file {'/home/rstory/.ssh':
    ensure => 'directory',
    owner => 'rstory',
    group => 'rstory',
    mode => 0700,
  }
  ssh_authorized_key { 'rstory@sparta':
    user => 'rstory',
    type => 'ssh-dss',
    key => 'AAAAB3NzaC1kc3MAAACBAL/xgoAUUVy3h6i+bRHcz+FWL7gResNPw2CiE+y9ToFXcnO2Pi38cX3VhLNPMf5k1SCix5cZBCPNTalbzmT0XJk6GYIZJSz0TA5mBTwkmu5ce0gPpJ3oNlnVyRBGan4K2c6AHHTL4cYH1svQ04RIR9WWirlMbRm6tRenkeLr1aXNAAAAFQCaI8SmXPz2f6PaJQ6sUDj3J5PrBwAAAIBC+QabiCOhToTVhT39JYn9QvVAGOsB4ZJTo+/MxENDBjpX5N9XzRjZZPl3Kbumav/BoekMiN32ubFTahg8GdL6j8M0IXaOlCutmPuZvFCMKrzBWYgP9wVq1DUFgiGtcRgYjE7hskKMQZZ7zR0NRCpgWBuaybIMXNFmU2NJIxcgOgAAAIEAh2E6+fpOZgCkKO6THEB5G+07ZZG/zx/tiqFVbFZYWyXAJoJRTsxCSu/49WElyrkJcKS37of441FFLD+/4pAc0j/XUdfSFsefP/oVtfi07VHNLa/z13MqZGoUWmkiehan/LGkM2+3CATBbfwmyJE3l75NmY1FToxjoSnEXVjHb9g=',
  }
}
