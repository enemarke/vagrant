class vagrant_puppetdb {
  sudo::conf { 'vagrant':
    priority => 01,
    content  => "vagrant ALL=(ALL) NOPASSWD: ALL",
  }

  class { '::puppetdb::globals': }

  package { 'puppetdb-termini': }

  class { '::puppetdb':  }

  service { 'puppetserver': }
}