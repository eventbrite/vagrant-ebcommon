begin
  require 'vagrant'
rescue LoadError
  abort 'vagrant-ebcommon must be loaded in a Vagrant environment.'
end

begin
  require 'vagrant-puppet-fact-generator'
rescue LoadError
  abort 'vagrant-ebcommon depends on the `vagrant-puppet-fact-generator` plugin.'
end

# Add our custom translations to the load path
I18n.load_path << File.expand_path("../../../locales/en.yml", __FILE__)

module VagrantPlugins
  module Ebcommon
    class Plugin < Vagrant.plugin('2')
      name 'vagrant-ebcommon'
      description <<-DESC
A Vagrant plugin to handle various Eventbrite workflows.
DESC

      # define configs
      config 'ebcommon' do
        require_relative 'config'
        Config
      end

      # define hooks
      action_hook 'setup_provision' do |hook|
        require_relative 'actions/setup_provision'
        hook.before VagrantPlugins::PuppetFactGenerator::Action::GenerateFacts, Action::SetupProvision
      end

      # define commands
      command 'clear-requirements-cache' do
        require_relative 'commands/clear_requirements_cache'
        Command
      end

      command 'start-selenium' do
        require_relative 'commands/start-selenium'
        Command
      end

      command 'stop-selenium' do
        require_relative 'commands/stop-selenium'
        Command
      end

    end
  end
end
