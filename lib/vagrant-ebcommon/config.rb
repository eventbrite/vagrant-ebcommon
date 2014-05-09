module VagrantPlugins
  module Ebcommon
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :vpn_urls
      attr_accessor :git_hook_repos
      attr_accessor :git_hook_root_dir

      def initialize
        @vpn_urls = UNSET_VALUE
        @git_hook_repos = UNSET_VALUE
        @git_hook_root_dir = UNSET_VALUE
      end

      def finalize!
        @vpn_urls = nil if @vpn_urls == UNSET_VALUE
        @git_hook_repos = nil if @git_hook_repos == UNSET_VALUE
        @git_hook_root_dir = nil if @git_hook_root_dir == UNSET_VALUE
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
        if @git_hook_repos
          if not @git_hook_repos.kind_of?(Array)
            errors << '`git_hook_repos` must be a list of paths to copy hooks to'
          end
        end
        if @git_hook_repos and not @git_hook_root_dir
          errors << '`git_hook_root_dir` must be set to the directory containing directories in `git_hook_repos`'
        end
        return { 'ebcommon' => errors }
      end

    end
  end
end
