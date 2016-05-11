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

== Summary ==

Puppet configuration to support an RPKI publication server and associated
infrastructure.

This presumes there are multiple 'publication servers' ready to accept
rsync connections (rcynic connections) from the rest of the RPKI participants,
and a single server storing the private key data away from public eyes. A
puppet service contains configuration, and there are one or more syslog
servers.

The rpki-mgmt puppet module is automatically pulled from GitHub once a day.

== RPKI setup ==

The RPKI services are managed by this configuration/system are offered using
the Dragon Research Labs reference platform. This puppet configurationes does
not (yet) install and manage the RPKI.net software. It must be installed prior
to deploying this puppet configuration. A 'get going in 10 minutes' script is
available here:

  <http://rpki.net/wiki/doc/RPKI/doc/RPKI/Installation/UbuntuRP>

The basic rpkid services, data locations and processes are:

- rpkid - writes stuff to mysql, and to disk for pubd
- pubd - can offer services to clients
- rsyncd (publication point) - shares rpki/publication's content

The rpki-mgmt puppet module will push all publication content to rsyncd
servers, run a script from cron to wrangle the publication data out to all
publication servers and move the rsyncd configuration to keep track of 'HEAD'
for this data.

Rsyncd will be managed by inetd/xinetd, so each client will see a clean and
unchanging dataset to retrieve. Rotation of that data off the disk will happen
in a timely fashion as well.

== Puppet config ==

The basic systems configured in the provided site.pp.dist example are:

puppet.example.com       - puppet-master server
ca.example.com           - master rpki server
publish-1.example.com    - publication server AP
log-1.example.com        - syslog collection server EU

Additional publication or log servers can easily be added to the appropriate
node definitions in site.pp.dist.

Several global variables that need to be defined:

  $syslog_servers : syslog destination(s) to be configured on all nodes
  $pupper_server  : puppet server to be configure on all nodes

There are 2 optional globals:
  $ssh_client_range : an IP range used to restrict ssh access to all nodes.
                      Default is '0.0.0.0/0', allowing any IP.
  $ssh_unrestricted_port: a port to be allowed for any IP (e.g. a secondary
                          and non-default port for ssh).

At the bottom of the site.pp.dist is a common_config class which can be used
to add any additional puppet config to be included for all nodes. e.g.
adding users and or additional packages.


== Configuration Script ==

A shell script, generate-rpki-mgmt-config.sh, is included to help in creating
puppet configuration based on user input.

Here is an example run of the script which sets up

- a single master cerficate authority
- a single puppet server
- publication points and syslog servers for a region (eg. US)
- publication points and syslog servers for a second region (eg. EU)

This script should be run on the puppet server, as it creates a directory
for the github repo and performan an initial pull of the repo.

- - - - - INITIAL script run - - - - -

[puppet] # ./generate-rpki-mgmt-config.sh
* Base directory for rpki-mgmt git repo (default: /var/lib/rpki-mgmt)
:
You entered [/var/lib/rpki-mgmt]. Is this correct (Y/n)?

* Git branch to track (default: master)
:
You entered [master]. Is this correct (Y/n)?

* UNIX Group for rpki-mgmt directory (default: rpki-mgmt)
:
You entered [rpki-mgmt]. Is this correct (Y/n)?

* (Optional) IP range for allowing ssh access to all servers (default: )
: 10.11.12.0/24
You entered [10.11.12.0/24]. Is this correct (Y/n)?

* Host name of puppet server (default: )
: puppet.example.com
You entered [puppet.example.com]. Is this correct (Y/n)?

* Host name of RPKI CA/RP server (default: )
: rpki-ca.example.com
You entered [rpki-ca.example.com]. Is this correct (Y/n)?

* Host name(s) of syslog-ng server(s)
[ enter one item per line; blank line to end, q to quit. ]
: log-1.us.example.com
: log-2.us.example.com
:
You entered [log-1.us.example.com log-2.us.example.com]. Is this correct (Y/n)?

* Host name(s) of RPKI publication server(s)
[ enter one item per line; blank line to end, q to quit. ]
: rpki-pub-1.us.example.com
: rpki-pub-2.us.example.com
:
You entered [rpki-pub-1.us.example.com rpki-pub-2.us.example.com]. Is this correct (Y/n)?

* rsync banner for RPKI publication server(s) (default: RPKI Publication Service)
: Example RPKI Publication Service (US)
You entered [Example RPKI Publication Service (US)]. Is this correct (Y/n)?

* Confirm Configuration
Base directory for rpki-mgmt git repo : /var/lib/rpki-mgmt
Git branch to track                   : master
UNIX Group for rpki-mgmt directory    : rpki-mgmt
IP range for ssh access to all servers: 10.11.12.0/24
Host name of pupper server            : puppet.example.com
Host name of RPKI CA/RP server        : rpki-ca.example.com
Host name(s) of syslog-ng server(s)   : log-1.us.example.com log-2.us.example.com
Host name(s) of RPKI publication server(s): rpki-pub-1.us.example.com rpki-pub-2.us.example.com
rsync banner for publication server(s): Example RPKI Publication Service (US)

Is this correct (Y/n)?
* Puppet config written to rpki-mgmt.pp.

* Creating group rpki-mgmt
* Creating rpki-mgmt base directory...

* Cloning rpki-mgmt master branch from github...
Cloning into 'rpki-mgmt.git'...
remote: Counting objects: 736, done.
remote: Compressing objects: 100% (53/53), done.
remote: Total 736 (delta 20), reused 0 (delta 0), pack-reused 677
Receiving objects: 100% (736/736), 101.24 KiB, done.
Resolving deltas: 100% (356/356), done.

* Copying rpki module to puppet directory...

* To continue installation/configuration, either:
    a) copy rpki-mgmt.pp to /etc/puppet/manifests/site.pp
  or
    b) copy contents of rpki-mgmt.pp to /etc/puppet/manifests/site.pp

  Then run puppet agent --test

- - - - - END script run - - - - -

- - - - - Additional group script run - - - - -

# ./generate-rpki-mgmt-config.sh -g
* Prefix for this group (default: )
: eu
You entered [eu]. Is this correct (Y/n)?

* Host name of puppet server (default: )
:
You entered []. Is this correct (Y/n)?

* Host name of RPKI CA/RP server (default: )
:
You entered []. Is this correct (Y/n)?

* Host name(s) of syslog-ng server(s)
[ enter one item per line; blank line to end, q to quit. ]
: log-1.eu.example.com
: log-2.eu.example.com
:
You entered [log-1.eu.example.com log-2.eu.example.com]. Is this correct (Y/n)?

* Host name(s) of RPKI publication server(s)
[ enter one item per line; blank line to end, q to quit. ]
: rpki-pub-1.eu.example.com
: rpki-pub-2.eu.example.com
:
You entered [rpki-pub-1.eu.example.com rpki-pub-2.eu.example.com]. Is this correct (Y/n)?

* rsync banner for RPKI publication server(s) (default: RPKI Publication Service)
: Example RPKI Publication Service (EU)
You entered [Example RPKI Publication Service (EU)]. Is this correct (Y/n)?

* Confirm Configuration
Host name of pupper server            :
Host name of RPKI CA/RP server        :
Host name(s) of syslog-ng server(s)   : log-1.eu.example.com log-2.eu.example.com
Host name(s) of RPKI publication server(s): rpki-pub-1.eu.example.com rpki-pub-2.eu.example.com
rsync banner for publication server(s): Example RPKI Publication Service (EU)

Is this correct (Y/n)?
* Puppet config written to rpki-mgmt.pp.

***  NOTE: nodes in the $eu_publication_servers list
        must be added to $publication_servers list manually
        so that they will be allowed to rsync from $ca_server.

* To continue installation/configuration, either:
    a) copy rpki-mgmt.pp to /etc/puppet/manifests/site.pp
  or
    b) copy contents of rpki-mgmt.pp to /etc/puppet/manifests/site.pp

  Then run puppet agent --test

- - - - - END script run - - - - -


== TODO ==
* two rsync repos on pub servers: rpki and rpki-archive
  * rpki only has latest data, rpki-archive has older pulls
* config option to use a local repo of these modules instead of pulling from
  github once a day
* document profiles so users can define their own roles
* make firewall management optional, integrate with puppetlabs firewall module
* make syslog management optional
* manage rpki.net software install/config
