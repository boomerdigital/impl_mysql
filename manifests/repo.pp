# This class adds the apt source to download the latest mysql packages

class impl_mysql::repo {

  include apt

  apt::source { 'mysql':
    location    => 'https://repo.mysql.com/apt/ubuntu/',
    release     => 'trusty',
    repos       => 'mysql-5.6',
    # TODO: Change source to MMP-controlled location
    key         => {
      'id'     => 'A4A9406876FCBD3C456770C88C718D3B5072E1F5',
      'source' => 'https://s3.amazonaws.com/boomerdigital-pgp-keys/mysql.asc'
    },
    include => { 'src' => false },
  }

}
