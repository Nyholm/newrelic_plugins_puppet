# = Class: newrelic_plugins::disk_monitor_plugin
#
# This class installs/configures/manages New Relic's Disk Monitor Plugin.
# It is supported on unix systems
#
# == Parameters:
#
# $license_key::     License Key for your New Relic account
#
# $install_path::    Install Path for New Relic Disk Plugin.
#                    Any downloaded files will be placed here.
#                    The plugin will be installed within this
#                    directory at `newrelic_disk_monitor_plugin`.
#
# $user::            User to run as
#
# $version::         New Relic Disk Monitor Plugin Version.
#                    Currently defaults to the latest version.
#
# == Requires:
#
#   puppetlabs/stdlib
#
# == Sample Usage:
#
#   class { 'newrelic_plugins::disk_monitor_plugin':
#     license_key    => 'NEW_RELIC_LICENSE_KEY',
#     install_path   => '/path/to/plugin',
#     user           => 'newrelic'
#   }
#
class newrelic_plugins::disk_monitor_plugin (
    $license_key,
    $install_path,
    $user,
    $version = $newrelic_plugins::params::disk_monitor_plugin_version,
) inherits params {

  include stdlib

  # verify ruby is installed
  newrelic_plugins::resource::verify_ruby { 'Disk Monitor Plugin': }

  # verify attributes
  validate_absolute_path($install_path)
  validate_string($version)
  validate_string($user)

  # verify license_key
  newrelic_plugins::resource::verify_license_key { 'Disk Monitor Plugin: Verify New Relic License Key':
    license_key => $license_key
  }

  $plugin_path = "${install_path}/newrelic_disk_monitor_plugin"

  # install plugin
  newrelic_plugins::resource::install_plugin { 'newrelic_disk_monitor_plugin':
    install_path => $install_path,
    plugin_path  => $plugin_path,
    download_url => "${newrelic_plugins::params::disk_monitor_download_baseurl}/${version}.tar.gz",
    version      => $version,
    user         => $user
  }

  # newrelic_plugin.yml template
  file { "${plugin_path}/config/newrelic_plugin.yml":
    ensure  => file,
    content => template('newrelic_plugins/disk_monitor/newrelic_plugin.yml.erb'),
    owner   => $user
  }

  # install bundler gem and run 'bundle install'
  newrelic_plugins::resource::bundle_install { 'Disk Monitor Plugin: bundle install':
    plugin_path => $plugin_path,
    user        => $user
  }

  # install init.d script and start service
  newrelic_plugins::resource::plugin_service { 'newrelic-disk-monitor-plugin':
    daemon         => './agent',
    daemon_dir     => $plugin_path,
    plugin_name    => 'Disk Monitor plugin',
    plugin_version => $version,
    user           => $user,
    run_command    => 'bundle exec',
    service_name   => 'newrelic-disk-monitor-plugin'
  }

  # ordering
  Newrelic_plugins::Resource::Verify_ruby['Disk Monitor Plugin']
  ->
  Newrelic_plugins::Resource::Verify_license_key['Disk Monitor Plugin: Verify New Relic License Key']
  ->
  Newrelic_plugins::Resource::Install_plugin['newrelic_disk_monitor_plugin']
  ->
  File["${plugin_path}/config/newrelic_plugin.yml"]
  ->
  Newrelic_plugins::Resource::Bundle_install['Disk Monitor Plugin: bundle install']
  ->
  Newrelic_plugins::Resource::Plugin_service['newrelic-disk-monitor-plugin']
}

