module VagrantPlugins
  module Ebcommon
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :vpn_urls

      def initialize
        @vpn_urls = UNSET_VALUE
      end

      def finalize!
        @vpn_urls = nil if @vpn_urls == UNSET_VALUE
      end

      def validate(machine)
        errors = []
        if @vpn_urls
          if not @vpn_urls.kind_of?(Array)
            errors << '`vpn_urls` must be a list of urls to test vpn connection'
          else
            @vpn_urls.each { |url|
              uri = URI(url)
              if not (uri.host and uri.port)
                errors << "`vpn_urls` must be a list of urls: '#{url}' is not valid."
              end
            }
          end
        end
        return { 'ebcommon' => errors }
      end

    end
  end
end
