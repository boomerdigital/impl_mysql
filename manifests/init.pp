# This class provisions 2 servers for mysql master-slave
# in MIXED replication mode
class impl_mysql {

  $impl_mysql_ecom_password = hiera('impl_mysql_ecom_password')
  $impl_mysql_repl_password = hiera('impl_mysql_repl_password')
  $impl_mysql_root_password = hiera('impl_mysql_root_password')
  $mysql_db_name           = hiera('mysql_db_name')
  $mysql_host_subnet       = hiera('mysql_host_subnet')
  $mysql_master            = hiera('mysql_master')
  $mysql_slave             = hiera('mysql_slave')

  class { 'impl_mysql::repo':
    before => [ Class['::mysql::server'],
                Class['::mysql::client'] ],
  }

  $mysql_default_options = {
    'mysqld' => {
      'bind-address'         => '0.0.0.0',
      'character-set-server' => 'utf8',
      'collation-server'     => 'utf8_unicode_ci',
      'init-connect'         => 'SET NAMES utf8',
      'max_connections'      => '512',
      'gtid-mode'                 => 'ON',
      'enforce-gtid-consistency'  => 'true',
      'log-slave-updates'         => 'true',
      'report-host'               => $ipaddress,
      'report-port'               => '3306',
      'master-info-repository'    => 'TABLE',
      'relay-log-info-repository' => 'TABLE',
      'sync-master-info'          => '1',
      'binlog-format'             => 'MIXED',
      'log-bin'                   => 'mysql-bin',
      'log-bin-trust-function-creators' => 'true',
      'binlog-do-db'                    => "${mysql_db_name}",
      'binlog-ignore-db'                => 'mysql',
      #'read-only'               => '1',
      'relay-log'               => 'mysql-relay-bin',
      'replicate-ignore-db'     => 'mysql',
      'replicate-do-db'         => "${mysql_db_name}"
    }
  }

  if ($role_type == 'mysql_master') {
    $other_host = $mysql_slave
    $mysql_add_options = {
      'mysqld' => {
        'server-id'                       => '1'
      }
    }
  }
  else {
    $other_host = $mysql_master
    $mysql_add_options = {
      'mysqld' => {
        'server-id'               => '2'
      }
    }
  }

  # Merges the mysqld section specifically
  $mysqld_override_options = merge($mysql_default_options['mysqld'], $mysql_add_options['mysqld'])
  $mysql_override_options = { 'mysqld' => $mysqld_override_options }

  class { '::mysql::server':
    root_password    => $impl_mysql_root_password,
    override_options => $mysql_override_options,
  }

  class { '::mysql::client': }

  mysql_database { $mysql_db_name:
    ensure   => 'present',
    charset  => 'utf8',
    collate  => 'utf8_unicode_ci',
    provider => 'mysql',
    require  => Class['::mysql::client'],
  }

  mysql_user { "ecom_svc@${mysql_host_subnet}":
    ensure        => 'present',
    password_hash => mysql_password($impl_mysql_ecom_password),
  }

  mysql_grant { "ecom_svc@${mysql_host_subnet}/${mysql_db_name}.*":
    ensure     => 'present',
    privileges => ['ALL'],
    table      => "${mysql_db_name}.*",
    user       => "ecom_svc@${mysql_host_subnet}",
    require    => Mysql_database[$mysql_db_name],
  }

  mysql_user { "root@%":
    ensure        => 'present',
    password_hash => mysql_password($impl_mysql_root_password),
  } ->

  mysql_grant { "root@%/*.*":
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['ALL'],
    table      => '*.*',
    user       => "root@%"
  }

  mysql_user { "rpl@${other_host}":
    ensure        => 'present',
    password_hash => mysql_password($impl_mysql_repl_password),
  } -> 

  mysql_grant { "rpl@${other_host}/*.*":
    ensure     => 'present',
#    privileges => ['ALL'],
    privileges => ['REPLICATION SLAVE', 'REPLICATION CLIENT', 'SUPER'],
    table      => '*.*',
    user       => "rpl@${other_host}"
  }

  mysql_user { "rpl@${ipaddress}":
    ensure        => 'present',
    password_hash => mysql_password($impl_mysql_repl_password),
  } ->

  mysql_grant { "rpl@${ipaddress}/*.*":
    ensure     => 'present',
#    privileges => ['ALL'],
    privileges => ['REPLICATION SLAVE', 'REPLICATION CLIENT', 'SUPER'],
    table      => '*.*',
    user       => "rpl@${ipaddress}"
  }

}
