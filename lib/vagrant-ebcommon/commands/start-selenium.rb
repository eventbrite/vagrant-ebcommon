module VagrantPlugins
  module Ebcommon
    class Command < Vagrant.plugin('2', 'command')

      def execute

        selserverjar = 'selenium-server-standalone-2.43.0.jar'

        opts = OptionParser.new do |o|
          o.banner = 'Usage: vagrant start-selenium [-h]'
          o.separator ''
          o.separator 'Will ensure that selenium has started on the host machine'
        end
        argv = parse_options opts
        return if !argv
        raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length > 0

        system "kill $(ps aux | grep '[s]elenium-server.jar' | awk '{print $2}') > /dev/null 2>&1"
        system "java -jar ../../src/www/eventbrite/common/automation/webdriver/server/#{selserverjar} -trustAllSSLCertificates > /dev/null 2>&1 &"
        @env.ui.success 'Selenium server started!'
      end

    end
  end
end
