#!/usr/bin/env ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'precise64'
  config.vm.box_url = 'http://files.vagrantup.com/precise64.box'

  config.ebcommon.vpn_urls = [
    'https://docs.evbhome.com',
    'https://reviews.evbhome.com',
  ]
  config.ebcommon.git_hook_root_dir = '/Volumes/eb_home/work'
  config.ebcommon.git_hook_repos = [
    'vagrant-ebcommon',
  ]

  config.vm.provision 'puppet' do |puppet|
    puppet.manifests_path = 'manifests'
    puppet.manifest_file = 'init.pp'
  end

end
