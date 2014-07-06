module VagrantPlugins
  module Ebcommon
    class Command < Vagrant.plugin('2', 'command')

      def execute

        opts = OptionParser.new do |o|
          o.banner = 'Usage: vagrant start-selenium [-h]'
          o.separator ''
          o.separator 'Will shutdown selenium on the host machine'
        end
        argv = parse_options opts
        return if !argv
        raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length > 0

        system "kill $(ps aux | grep '[s]elenium-server-standalone' | awk '{print $2}') > /dev/null 2>&1"
        @env.ui.success 'Selenium server stopped!'
      end

    end
  end
end
