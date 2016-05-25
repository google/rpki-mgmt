define rpki::rpki_repo()
{
  #--------------------------------------------------------------------
  # set up APT repo
  #--------------------------------------------------------------------
  # xxx: debian-ism
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
    #subscribe => File['/etc/apt/trusted.gpg.d/rpki-apt-gpg-key.asc'],
    #refreshonly => true,
    unless => "/usr/bin/apt-key list | /bin/grep -q 'rpki.net Debian/Ubuntu package signing key'",
  }  -> Package <| |>

  exec{'get rpki.net APT repo':
    command => "/usr/bin/wget -q -O /etc/apt/sources.list.d/rpki.list http://download.rpki.net/$rpki::params::apt_path && /usr/bin/apt-get update",
    creates => "/etc/apt/sources.list.d/rpki.list",
  }
  file{'/etc/apt/sources.list.d/rpki.list':
    mode => 0644,
    owner => 'root',
    group => 'root',
    require => Exec["get rpki.net APT repo"],
  } -> Package <| |>

}
