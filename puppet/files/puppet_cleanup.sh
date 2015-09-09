#!/bin/sh
#
#Copyright 2014 Google Inc. All Rights Reserved.
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
#
# Clean up behind stuck puppet instances, something makes puppet occassionally
# die and leave: /var/lib/puppet/state/puppetdlock
# If one of these exists for more than 2hrs, remove it and restart puppet.

LOCK=/var/lib/puppet/state/puppetdlock
STATE=/var/lib/puppet/state/state.yaml

# If there is a stale lock file OR the state file hasn't changed in
# 2 hours time, please kick puppet in the teeth and make it restart.
FIRST_CANDIDATE=$(find ${LOCK} -cmin +120)
SECOND_CANDIDATE=$(find ${STATE} -cmin +120)

if [ ! -z ${CANDIDATE} ]; then
  /bin/rm -f ${CANDIDATE}
  /etc/init.d/puppet stop
  /usr/bin/puppet --onetime --no-daemonize > /tmp/puppet.log 2>&1
  /etc/init.d/puppet start
fi


