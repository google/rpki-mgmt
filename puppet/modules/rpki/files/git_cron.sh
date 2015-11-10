#!/bin/sh
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
# Run from cron, this should perform a git-pull from the
# repository, storing content into an alternate location
# and then rsync that to puppet's usable data directory.
#
# After rsync, sort through the changes and move all puppet
# recipe/control files to their proper homes.
#
# Alternately we may also want to check all puppet .pp files
# to be sure they are the same between the repo and the system
# location.
#
set -x
# xxx: /etc/default is a debianism
if [ ! -f /etc/default/rpki-mgmt ] ; then
  echo 'No rpki-mgmt configuration file, exiting.'
  exit 1
fi

. /etc/default/rpki-mgmt

if [ -z ${INFRA_REPO} ]; then
    echo 'INFRA_REPO not configured, exiting.'
    exit 1
fi

LOG=$(mktemp -t tmp.rpki-mgmt.XXXX.$$)

# Binaries
GIT=/usr/bin/git
PUPPET=/usr/bin/puppet
RSYNC=/usr/bin/rsync

# Options for binaries which require options at runtime.
RSYNC_OPTS='-rpva --delete-after --delay-updates'
RSYNC_EXC='--exclude .git/'

# Check for the INFRASTRUCTURE notification lock file.
#
if [ ! -f ${GIT_INFRA_NOTIFY} ] ; then
  echo 'No INFRA notify file, exiting.'
else
  if [ -d ${INFRA_REPO} ] ; then
    #
    # Copy from the repository to the storage location.
    cwd=${CWD}
    cd ${INFRA_REPO}
      # Pull the repository to the temporary storage location.
      if [ -z ${INFRA_VERBOSE} ]; then
        ${GIT} pull > /tmp/git_pull.log 2>&1
      else
        ${GIT} pull 2>&1 | tee /tmp/git_pull.log
      fi
      cd ${cwd}

      # Use rsync to pull the repository into the puppet directory,
      # save a log of changes that can be sorted for important actions.
      if [ -z ${INFRA_VERBOSE} ]; then
        ${RSYNC} ${RSYNC_OPTS} ${RSYNC_EXC} ${INFRA_REPO}/ ${PUPPET_INFRA_DIR} > ${LOG} 2>&1
      else
        ${RSYNC} ${RSYNC_OPTS} ${RSYNC_EXC} ${INFRA_REPO}/ ${PUPPET_INFRA_DIR} 2>&1 | tee ${LOG}
      fi

      # if the log has \.pp or \.erb files, move these to the final location.
      $(/bin/egrep '\.(pp|erb)$' ${LOG} > /dev/null)
      if [ $?  -eq 0 ]; then
        cd ${PUPPET_INFRA_DIR}
        echo 'Moving puppet recipe stuff from git-repo to puppet location.'
        for file in $(/bin/egrep '\.(pp|erb)$' ${LOG}); do
          echo "Potentially moving: ${file}"
          newfile=$(echo ${file} | sed 's/^puppet/\/etc\/puppet/')
          # This should have worked, it's not reliable.
          # $(${PUPPET} apply --noop ${file})  > /dev/null 2>&1
          # if [ $? -eq 0 ]; then
          #   echo "Copying: ${file} to ${newfile}"
          #   cp ${file} ${newfile}
          # else
          #   echo "Not copying recipe, syntax failures occured."
          # fi
          echo "Copying: ${file} to ${newfile}"
          newdir=$(dirname ${newfile})
          mkdir -p ${newdir}
          cp ${file} ${newfile}
        done
      else
        echo "No pp files to relocate."
      fi
    fi
    if [ ! -z ${REMOVE_NOTIFY} ]; then
      /bin/rm ${GIT_INFRA_NOTIFY}
    fi
  fi


# Remove the temporary logfile if it is zero length.
if [ ! -s ${LOG} ] ; then
  /bin/rm ${LOG}
fi
