module VagrantPlugins
  module Ebcommon
    class Command < Vagrant.plugin('2', 'command')
      def execute
        @env.ui.info 'Clearing PIP requirements cache...'
        machine = @env.machine :default, :virtualbox
        machine.communicate.execute '/bin/rm /home/vagrant/python_venv/*/pip_requirements_cache'
      @env.ui.error '...cache cleared!'
      end
    end
  end
end
