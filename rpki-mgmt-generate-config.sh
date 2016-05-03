#!/bin/bash

query_val()
{
   local prompt="$1" var="$2" ans

   echo "$prompt"
   echo "[ default: ${!2} ]"
   while :
   do
      echo -n ": "
      read ans
      if [ -z "$ans" ]; then
         ans=${!2}
      fi

      echo -n "You entered [$ans]. Is this correct (Y/n)?"
      read yn
      case "$yn" in
         N|n) continue;;
         *) printf -v "$2" %s $ans
            break;;
      esac
   done
   #echo "$2 set to ${!2}"
   echo
}

query_vals()
{
   local prompt="$1" var="$2" ans

   echo "$prompt"
   echo "[ enter one item per line; blank line to end, q to quit. ]"
   echo "[ default: ${!2} ]"
   while :
   do
      while :
      do
         echo -n ": "
         read ans
         case "$ans" in
            "") break;;
            "q") exit;;
            *) if [ -z "${!2}" ]; then
                  printf -v "$2" %s "$ans"
               else
                  printf -v "$2" %s "${!2} $ans"
               fi
               ;;
         esac
      done

      echo -n "You entered [${!2}]. Is this correct (Y/n)?"
      read yn
      case "$yn" in
         N|n) printf -v "$2" %s ""
              continue;;
         *) break;;
      esac
   done
   #echo "$2 set to ${!2}"
   echo
}

node_role()
{
   local header="$1" role="$2" host
   shift 2
   cat >> $pp <<EOF
# ------------------------------------
# $header

EOF

   for host in $@
   do
      cat >> $pp <<EOF
node '$host'
{
  include $role
}

EOF
   done
}

#
# defaults
#

# group for rpki-mgmt base directory
rm_group=${RPKIMGMT_GROUP:-rpki-mgmt}

# rpki-mgmt base directory
rm_base=${RPKIMGMT_BASE:-/var/lib/rpki-mgmt}

# rpki-mgmt branch to track
rm_branch=${RPKIMGMT_BRANCH:-master}

# frequency to pull from github
rm_pull=${RPKIMGMT_PULL_FREQUENCY:-daily}

# puppet server
rm_puppet=${RPKIMGMT_PUPPET_SERVER}

# syslog servers
rm_syslog=${RPKIMGMT_SYSLOG_SERVERS}

# rpki masters (CA/validators)
rm_master=${RPKIMGMT_MASTER_SERVERS}

# rpki publication servers
rm_publication=${RPKIMGMT_PUBLICATION_SERVERS}

# rsync banner
rm_rsync_banner=${RPKIMGMT_PUBLICATION_SERVERS:-RPKI Publication Service}

# allowed IP range for ssh
rm_ssh=${RPKIMGMT_:-0.0.0.0/0}

# output file
pp="rpki-mgmt.pp"

if [ -e $pp ]; then
   echo "File $pp already exists. Remove or rename it to continue."
   exit 2
fi

# ask for values
query_val "Base directory for rpki-mgmt git repo" rm_base
query_val "Git branch to track" rm_branch
query_val "UNIX Group for rpki-mgmt directory" rm_group
query_val "(Optional) IP range for allowing ssh access to all servers" rm_ssh
query_val "Host name of puppet server" rm_puppet
query_vals "Host name(s) of syslog-ng server(s)" rm_syslog
query_vals "Host name(s) of RPKI CA/RP server(s)" rm_master
query_vals "Host name(s) of RPKI publication server(s)" rm_publication
if [ -n "$rm_publication" ]; then
   query_val "rsync banner for RPKI publication server(s)" rm_rsync_banner
fi

# double check
echo "============= Configuration ================="
echo "Base directory for rpki-mgmt git repo : $rm_base"
echo "Git branch to track                   : $rm_branch"
echo "UNIX Group for rpki-mgmt directory    : $rm_group"
echo "IP range for ssh access to all servers: $rm_ssh"
echo "Host name of pupper server            : $rm_puppet"
echo "Host name(s) of syslog-ng server(s)   : $rm_syslog"
echo "Host name(s) of RPKI CA/RP server(s)  : $rm_master"
echo "Host name(s) of RPKI publication server(s): $rm_publication"
if [ -n "$rm_publication" ]; then
   echo "rsync banner for publication server(s):" $rm_rsync_banner
fi
echo
echo -n "Is this correct (Y/n)?"
read yn
case "$yn" in
   N|n) exit 1;;
   *) ;;
esac

# write to file
echo "#This file generated using $0 on `date`" > $pp
cat >> $pp <<EOF

# ---------------------------------------------------------------
# Globals
# ---------------------------------------------------------------

# ip range for ssh access on port 22
\$ssh_client_range = '$rm_ssh'

# optional port for ssh access without client ip restrictions
# Default is '', which means no rule will be added.
# (technically it just adds a TCP rule for the port, so it could be
#  any service, not just ssh.)
\$ssh_unrestricted_port = ''

\$puppet_server = '$rm_puppet'

# syslog servers that all clients will use 
\$syslog_servers = [
EOF

for host in $rm_syslog
do
   echo "                   '$host'," >> $pp
done

cat >> $pp <<EOF
                  ]

# publication servers
\$publication_servers = [
EOF

for host in $rm_publication
do
   echo "                   '$host'," >> $pp
done

cat >> $pp <<EOF
                        ]

\$rsync_module_description = '$rm_rsync_banner'

# ---------------------------------------------------------------
# Nodes
# ---------------------------------------------------------------

EOF

node_role "syslog servers" "rpki::role::log_server" $rm_syslog
node_role "puppet servers" "rpki::role::puppet_master" $rm_puppet
node_role "RPKI CA/RP servers" "rpki::role::rpki_master" $rm_master
node_role "publication servers" "rpki::role::pub_server" $rm_publication

cat >> $pp <<EOF

# ------------------------------------
# For unknown nodes, configure puppet server
# and just add rpki_common_config
#
node "default" {
  include stdlib
  class { "rpki_common_config": }

  class { "rpki::puppet_config":
     puppetServer => '\$puppet_server',
  }
}

# ---------------------------------------------------------------------
# Classes
# ---------------------------------------------------------------------

#
# All roles include rpki_common_config. This is the place to define resources
# which should be installed and configured on every machine.
#
class rpki_common_config {

  ##
  ## extra packages for all nodes
  ##
  #package { [ 'vim-nox', 'sudo', 'tcpdump' ]:
  #  ensure => latest,
  #}

  ##
  ## --- Users ---
  ##
  ## morrowc
  ##
  #user {'morrowc':
  #  ensure => 'present',
  #}

  ## rstory
  ##
  #user {'rstory':
  #  ensure => 'present',
  #  shell => '/bin/bash',
  #}
}
EOF

echo "Puppet config written to $pp."
echo

echo "Creating rpki-mgmt base directory..."
mkdir -p $rm_base
if [ ! -d $rm_base ]; then
   echo "Failed to create directory $rm_base"
   exit 1
fi
cd $rm_base
echo

echo "Cloning rpki-mgmt $rm_branch branch from github..."
/usr/bin/git clone -b $rm_branch https://github.com/google/rpki-mgmt.git rpki-mgmt.git
if [ ! -d rpki-mgmt.git ]; then
   echo "Failed to clone rpki-mgmt git repo"
   exit 1
fi
echo

echo "Copying rpki module to puppet directory..."
cp -a /var/lib/rpki-mgmt/rpki-mgmt.git/puppet/modules/rpki/ /etc/puppet/modules/

echo "To continue installation/configuration, either:"
echo "    a) copy rpki-mgmt.pp to /etc/puppet/manifests/site.pp"
echo "  or"
echo "    b) copy contents of rpki-mgmt.pp to /etc/puppet/manifests/site.pp"
echo
echo "Then run puppet --apply"
echo
