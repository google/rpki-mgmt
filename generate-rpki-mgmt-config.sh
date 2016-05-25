#!/bin/bash

usage()
{
   echo "$0 [-g]"
   echo "  -g: define additional group of nodes"
   echo
   exit 1
}

# query_val "Prefix for this group" rm_base_prefix
query_val()
{
   local prompt="$1" var="$2" ans
   qv_ans=
   echo "* $prompt (default: ${!var})"
   while :
   do
      echo -n ": "
      read ans
      if [ -z "$ans" ]; then
         ans=${!var}
      fi

      echo -n "You entered [$ans]. Is this correct (Y/n)?"
      read yn
      case "$yn" in
         N|n) continue;;
         *) break;;
      esac
   done
   qv_ans="$ans"
   echo
}

query_vals()
{
   local prompt="$1" var="$2" ans

   echo "* $prompt"
   echo "[ enter one item per line; blank line to end, q to quit. ]"
   qv_ans=
   while :
   do
      while :
      do
         echo -n ": "
         read ans
         case "$ans" in
            "") break;;
            "q") exit;;
            *) if [ -z "$qv_ans" ]; then
                  qv_ans="$ans"
               else
                  qv_ans+=" $ans"
               fi
               ;;
         esac
      done

      echo -n "You entered [$qv_ans]. Is this correct (Y/n)?"
      read yn
      case "$yn" in
         N|n) qv_ans=""
              continue;;
         *) break;;
      esac
   done
   echo
}

node_role()
{
   local header="$1" role="$2" hosts host pfx
   shift 2
   hosts="$*"
   [ -z "$hosts" ] && return
   cat >> "$pp" <<EOF
# ------------------------------------
# $header

EOF

   pfx=" "
   echo -n "node" >> "$pp"
   for host in $hosts
   do
      echo -n "$pfx'$host'" >> "$pp"
      pfx=", "
   done
   cat >> "$pp" <<EOF
 {
  include $role
}

EOF
}

# node_wrapper $rm_base_prefix "rpki::role::log_server"
node_wrapper()
{
   local prefix="$1" role="$2"

   cat >> "$pp" <<EOF
class $prefix::$role
{
EOF
   if [ -n "$rm_rsync_banner" ]; then
      echo "   \$rsync_module_description = \"\$${prefix}_rsync_module_description\"" >> "$pp"
   fi
   if [ -n "$rm_ssh" ]; then
      echo "   \$ssh_client_range = \"\$${prefix}_ssh_client_range\"" >> "$pp"
   fi
   #   echo "   \$ssh_unrestricted_port = \"\$${prefix}_ssh_unrestricted_port\"" >> "$pp"
   if [ -n "$rm_puppet" ]; then
      echo "   \$puppet_server = \"\$${prefix}_puppet_server\"" >> "$pp"
   fi
   if [ -n "$rm_master" ]; then
      echo "   \$ca_server = \"\$${prefix}_ca_server\"" >> "$pp"
   fi
   if [ -n "$rm_syslog" ]; then
      echo "   \$syslog_servers = \$${prefix}_syslog_servers" >> "$pp"
   fi
   if [ -n "$rm_publication" ]; then
      echo "   \$publication_servers = \$${prefix}_publication_servers" >> "$pp"
   fi
   cat >> "$pp" <<EOF
   include $role
}

EOF
}

###########################################################################
# defaults
###########################################################################

# group for rpki-mgmt base directory
rm_group=${RPKIMGMT_GROUP:-rpki-mgmt}

# rpki-mgmt base directory
rm_base=${RPKIMGMT_BASE:-/var/lib/rpki-mgmt}

# rpki-mgmt branch to track
rm_branch=${RPKIMGMT_BRANCH:-master}

# TODO: frequency to pull from github
#rm_pull=${RPKIMGMT_PULL_FREQUENCY:-daily}

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
rm_ssh=${RPKIMGMT_SSH_RANGE}

group=0
while getopts g opt
do
    case "$opt" in
      g)  group=1;;
      \?) usage;;
    esac
done
shift $(( OPTIND - 1 ))

if [ $group -eq 1 ]; then
   query_val "Prefix for this group" rm_base_prefix
   rm_base_prefix="$qv_ans"
   rm_prefix="${rm_base_prefix}_"
   rm_role_prefix="${rm_base_prefix}::"
   #pp="rpki-mgmt-$rm_base_prefix.pp"
#else
#   pp="rpki-mgmt.pp"
fi
pp="rpki-mgmt.pp"

# ask for values
if [ $group -eq 0 ]; then
   query_val "Base directory for rpki-mgmt git repo" rm_base
   rm_base="$qv_ans"
   query_val "Git branch to track" rm_branch
   rm_branch="$qv_ans"
   query_val "UNIX Group for rpki-mgmt directory" rm_group
   rm_group="$qv_ans"
   query_val "(Optional) IP range for allowing ssh access to all servers" rm_ssh
   rm_ssh="$qv_ans"
fi
query_val "Host name of puppet server" rm_puppet
rm_puppet="$qv_ans"
query_val "Host name of RPKI CA/RP server" rm_master
rm_master="$qv_ans"
query_vals "Host name(s) of syslog-ng server(s)" rm_syslog
rm_syslog="$qv_ans"
query_vals "Host name(s) of RPKI publication server(s)" rm_publication
rm_publication="$qv_ans"
if [ -n "$rm_publication" ]; then
   query_val "rsync banner for RPKI publication server(s)" rm_rsync_banner
   rm_rsync_banner="$qv_ans"
fi

# double check
echo "* Confirm Configuration"
if [ $group -eq 0 ]; then
   echo "Base directory for rpki-mgmt git repo : $rm_base"
   echo "Git branch to track                   : $rm_branch"
   echo "UNIX Group for rpki-mgmt directory    : $rm_group"
   echo "IP range for ssh access to all servers: $rm_ssh"
fi
echo "Host name of pupper server            : $rm_puppet"
echo "Host name of RPKI CA/RP server        : $rm_master"
echo "Host name(s) of syslog-ng server(s)   : $rm_syslog"
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
echo "# This file generated using $0 on $(date)" >> "$pp"
cat >> "$pp" <<EOF

# ---------------------------------------------------------------
# Globals
# ---------------------------------------------------------------

EOF

if [ $group -eq 0 -o -n "$rm_ssh" ]; then
   cat >> "$pp" <<EOF
# ip range for ssh access on port 22
\$${rm_prefix}ssh_client_range = '$rm_ssh'

EOF
fi

if [ $group -eq 0 ]; then
   cat >> "$pp" <<EOF
# optional port for ssh access without client ip restrictions
# Default is '', which means no rule will be added.
# (technically it just adds a TCP rule for the port, so it could be
#  any service, not just ssh.)
\$${rm_prefix}ssh_unrestricted_port = ''

EOF
fi

if [ $group -eq 0 -o -n "$rm_puppet" ]; then
   cat >> "$pp" <<EOF
# puppet master
\$${rm_prefix}puppet_server = '$rm_puppet'

EOF
fi

if [ $group -eq 0 -o -n "$rm_master" ]; then
   cat >> "$pp" <<EOF
# RPKI CA
# Hosts assigned the pub_server role will pull data from this host
\$${rm_prefix}ca_server = '$rm_master'

EOF
fi

if [ $group -eq 0 -o -n "$rm_syslog" ]; then
   cat >> "$pp" <<EOF
# syslog servers that all clients will use
\$${rm_prefix}syslog_servers = [
EOF

for host in $rm_syslog
do
   echo "                   '$host'," >> "$pp"
done

cat >> "$pp" <<EOF
   ]

EOF
fi

if [ $group -eq 0 -o -n "$rm_publication" ]; then
   cat >> "$pp" <<EOF
# publication servers
# Hosts assigned the rpki_master role will allow hosts in this list to
# connect via rsync. If this value is empty, any host will be able to
# connect via rsync.
\$${rm_prefix}publication_servers = [
EOF

for host in $rm_publication
do
   echo "                   '$host'," >> "$pp"
done

cat >> "$pp" <<EOF
  ]

EOF
fi

if [ $group -eq 0 -o -n "$rm_rsync_banner" ]; then
   cat >> "$pp" <<EOF
# banner text displayed by pub_server nodes
\$${rm_prefix}rsync_module_description = '$rm_rsync_banner'

EOF
fi

cat >> "$pp" <<EOF
# ---------------------------------------------------------------
# ${rm_base_prefix} Nodes
# ---------------------------------------------------------------

EOF

if [ $group -eq 1 ]; then
   cat >> "$pp" <<EOF
#
# wrappers for group $rm_base_prefix
#
EOF
   node_wrapper $rm_base_prefix "rpki::role::log_server"
   node_wrapper $rm_base_prefix "rpki::role::puppet_master"
   node_wrapper $rm_base_prefix "rpki::role::rpki_master"
   node_wrapper $rm_base_prefix "rpki::role::pub_server"
fi

node_role "syslog servers" "${rm_role_prefix}rpki::role::log_server" $rm_syslog
node_role "puppet servers" "${rm_role_prefix}rpki::role::puppet_master" $rm_puppet
node_role "RPKI CA/RP servers" "${rm_role_prefix}rpki::role::rpki_master" $rm_master
node_role "publication servers" "${rm_role_prefix}rpki::role::pub_server" $rm_publication

if [ $group -eq 0 ]; then
   cat >> "$pp" <<EOF
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
fi

echo "* Puppet config written to $pp."
echo

if [ $group -eq 0 ]; then
   echo "* Creating group $rm_group"
   groupadd -r "$rm_group" 2>/dev/null
   if [ $? -ne 0 -a $? -ne 9 ]; then
       echo "Failed to add group $rm_group"
       exit 1
   fi

   if [ ! -d "$rm_base" ]; then
       echo "* Creating rpki-mgmt base directory..."
       mkdir -p "$rm_base"
       if [ ! -d "$rm_base" ]; then
           echo "Failed to create directory $rm_base"
           exit 1
       fi
       echo
   fi
   cd "$rm_base"

   if [ ! -d rpki-mgmt.git ]; then
       echo "* Cloning rpki-mgmt $rm_branch branch from github..."
       /usr/bin/git clone -b "$rm_branch" https://github.com/google/rpki-mgmt.git rpki-mgmt.git
       if [ ! -d rpki-mgmt.git ]; then
           echo "Failed to clone rpki-mgmt git repo"
           exit 1
       fi
       echo

       echo "* Copying rpki module to puppet directory..."
       cp -a "$rm_base/rpki-mgmt.git/puppet/modules/rpki/" /etc/puppet/modules/
       echo
   fi

   chgrp -R "$rm_group" "$rm_base"

   echo "* Installing required puppet modules"
   puppet module install puppetlabs-stdlib puppetlabs-inifile

else

    if [ -n "$rm_publication" -a -z "$rm_master" ]; then
        echo "***  NOTE: nodes in the \$${rm_prefix}publication_servers list"
        echo "        must be added to \$publication_servers list manually"
        echo "        so that they will be allowed to rsync from \$ca_server."
        echo
    fi
fi

echo "* To continue installation/configuration, either:"
echo "    a) copy $pp to /etc/puppet/manifests/site.pp"
echo "  or"
echo "    b) copy contents of $pp to /etc/puppet/manifests/site.pp"
echo
echo "  Then run puppet agent --test"
echo
