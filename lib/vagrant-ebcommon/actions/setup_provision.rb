require 'fileutils'
require 'timeout'
require 'socket'
require_relative '../errors'

module VagrantPlugins
  module Ebcommon
    class Action
      class SetupProvision
        def initialize(app, env)
          @app = app
          @env = env
          @ebcommon = env[:machine].config.ebcommon
          @puppet_fact_generator = @env[:machine].config.puppet_fact_generator

          provisioner = @env[:machine].config.vm.provisioners[0]
          @puppet_config = provisioner ? provisioner.config: nil
          @vagrant_git_commiter_details = @env[:machine].env.local_data_path.join(
            'git_commit_details'
          )
        end

        # Some of our requirements contain references to private eventbrite
        # github repos. We'll fail to clone these unless we've added our
        # ssh-keys so their available to vagrant.
        def setup_ssh_keys
          @env[:ui].info 'Ensuring ssh-keys have been added via `ssh-add`...'
          current_keys = `ssh-add -l`
          if current_keys.include? 'no identities'
            success = system('ssh-add')
            if success
              @env[:ui].success '...ssh-keys successfully added'
            else
              @env[:ui].warn 'failed to call `ssh-add`, some requirements may fail to install'
            end
          else
            @env[:ui].info '...ssh-keys detected, skipping `ssh-add`'
          end
        end

        # Copy over our git commit hooks
        def setup_git_hooks
          plugin_hooks_dir = File.expand_path File.join(File.dirname(__FILE__), '..', 'files', 'git_hooks')
          git_hooks = Dir.entries(plugin_hooks_dir).select {|f| !File.directory? f}
          if @ebcommon.git_hook_repos
            @env[:ui].info 'Copying over git commit hooks...'
          end

          @ebcommon.git_hook_repos.each do |repo_path|
            target_directory = File.join @ebcommon.git_hook_root_dir, repo_path, '.git', 'hooks'
            if File.directory? target_directory
              git_hooks.each do |hook|
                @env[:ui].success "Copying over git hook: #{hook} to #{target_directory}"
                source = File.join plugin_hooks_dir, hook
                FileUtils.cp source, target_directory
              end
            end
          end
        end

        # In order to provision vagrant, we require you to be in the office or
        # connected to VPN. There are several packages that are hosted
        # internally and everything will fail miserably if you're not on our
        # network.
        def ensure_vpn
          if not ENV['FORCE_PROVISION'] and @ebcommon.vpn_urls
            vpn_valid = false
            @ebcommon.vpn_urls.each { |url|
              vpn_valid = ping url
              break if vpn_valid
            }
            if not vpn_valid
              raise Ebcommon::Errors::VPNRequired.new
            end
            @env[:ui].success 'VPN connection verified, continuing provision.'
          end
        end

        # We store the git commiter details in a file within the vagrant
        # directory. We do this so we're not always prompting a user for their
        # full name and email.  If they don't provide them the first time
        # around, we'll opt them out and never ask them again.
        #
        # :Returns:
        #   - dict of github creds
        def fetch_git_commiter_details_from_file
          creds = {}
          contents = ""
          if File.exists?(@vagrant_git_commiter_details)
            File.open(@vagrant_git_commiter_details, 'r') do |f|
              while line = f.gets
                contents += line
              end
            end
          end
          if not contents.empty?
            creds = JSON.parse contents
          end
          return creds
        end

        # Write the git commiter details to a file so we can load them next
        # time the user starts up vagrant.
        def write_git_commiter_details(full_name, email)
          if full_name.empty? and email.empty?
            creds = {'optout' => true}
          else
            creds = {'full_name' => full_name, 'email' => email}
          end
          File.open(@vagrant_git_commiter_details, 'w') do |f|
            f.write(JSON.dump(creds))
          end
        end

        # When a user is setting up a new vagrant, prompt them for their full
        # name and email. We'll set these within vagrant so we avoid people
        # accidently commiting as the "vagrant" user.
        def generate_git_commiter_facts()
          existing_details = fetch_git_commiter_details_from_file()
          # don't set the git configs if the user opted out
          if existing_details.has_key? 'optout'
            return
          end

          if existing_details.any?
            full_name = existing_details.fetch 'full_name', nil
            email = existing_details.fetch 'email', nil
          elsif existing_details.has_key? 'optout'
            full_name = nil
            email = nil
          else
            @env[:ui].warn \
              "You'll be prompted to enter your full name and eventbrite email.\n"\
              "We'll set these for you within your vagrant's .gitconfig.\n"\
              "This will avoid accidentally committing code as 'vagrant'.\n"\
              "If you ever want to reset these, remove\n"\
              "#{@vagrant_git_commiter_details} from your vagrant directory.\n"
            full_name = @env[:ui].ask 'Enter your full name: '
            email = @env[:ui].ask 'Enter your eventbrite email: '
            write_git_commiter_details(full_name, email)
          end
          if not full_name.empty? or not email.empty?
            @env[:ui].success "Will setup global github details in vagrant."\
              " Full Name: #{full_name}, Email: #{email}"
          end
          # NB: We have to escape single quotes for the bash command line.
          # These facts will get run with puppet_apply like:
          # FACTER_github_username='Brian O'Niell'. We use this special
          # escaping to concat an escaped single quote with the rest of the
          # string, outputting: FACTER_github_username='Brian O'\''Niell'
          @puppet_fact_generator.add_fact(
            'github_full_name',
            full_name.gsub("'", "'\\\\''")
          )
          @puppet_fact_generator.add_fact('github_email', email)
        end

        def call(env)
          provision_enabled = env.has_key?(:provision_enabled) ? env[:provision_enabled] : true
          if provision_enabled
            ensure_vpn()
            setup_ssh_keys()
            setup_git_hooks()
            generate_git_commiter_facts()
          end
          @app.call(env)
        end

        private

          def ping(url)
            uri = URI(url)
            begin
              timeout(1) do
                s = TCPSocket.new(uri.host, uri.port)
                s.close
              end
            rescue Timeout::Error, SocketError
              return false
            end
            return true
          end

      end
    end
  end
end
