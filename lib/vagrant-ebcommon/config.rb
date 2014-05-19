module VagrantPlugins
  module Ebcommon
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :vpn_urls
      attr_accessor :vpn_timeout
      attr_accessor :git_hook_repos
      attr_accessor :git_hook_root_dir

      def initialize
        @vpn_urls = UNSET_VALUE
        @vpn_timeout = UNSET_VALUE
        @git_hook_repos = UNSET_VALUE
        @git_hook_root_dir = UNSET_VALUE
      end

      def finalize!
        @vpn_urls = nil if @vpn_urls == UNSET_VALUE
        @vpn_timeout = 5 if @vpn_timeout == UNSET_VALUE
        @git_hook_repos = nil if @git_hook_repos == UNSET_VALUE
        @git_hook_root_dir = nil if @git_hook_root_dir == UNSET_VALUE
      end

      def validate(machine)
        errors = []
        if @vpn_urls
          if !@vpn_urls.is_a?(Array)
            errors << '`vpn_urls` must be a list of urls to test vpn connection'
          else
            @vpn_urls.each { |url|
              uri = URI(url)
              if !(uri.host && uri.port)
                errors << "`vpn_urls` must be a list of urls: '#{url}' is not valid."
              end
            }
          end
        end
        if @vpn_timeout && !@vpn_timeout.is_a?(Integer)
          errors << '`vpn_timeout` must be an integer which represents the timeout in seconds to wait'
        end
        if @git_hook_repos && !@git_hook_repos.is_a?(Array)
          errors << '`git_hook_repos` must be a list of paths to copy hooks to'
        end
        if @git_hook_repos && !@git_hook_root_dir
          errors << '`git_hook_root_dir` must be set to the directory containing directories in `git_hook_repos`'
        end
        return { 'ebcommon' => errors }
      end

    end
  end
end
