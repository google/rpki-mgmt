#
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
$rpki_pub_servers = {
                     'rpki-aspac-01' => 1,
                     'rpki-aspac-02' => 1,
                     'rpki-aspac-03' => 1,
                     'rpki-emea-01' => 1,
                     'rpki-emea-02' => 1,
                     'rpki-us-01' => 1,
                     'rpki-us-02' => 1,
                     'rpki-us-03' => 1,
                    }
$syslog_servers = {
                   'rpki-syslog-emea' => 1,
                   'rpki-syslog-na' => 1,
                  }

node "default" {
  include apt
  include cron
  include rpki
  include configs
  include scripts
  include services
}
