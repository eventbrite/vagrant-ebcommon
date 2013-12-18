module VagrantPlugins
  module Ebcommon
    class Action
      class SetupProvision
        def initialize(app, env)
          @app = app
          @env = env

          provisioner = @env[:global_config].vm.provisioners[0]
          @puppet_config = provisioner ? provisioner.config: nil
          @vagrant_git_commiter_details = '.VAGRANT_GIT_COMMITER_DETAILS'
        end

        # Some of our requirements contain references to private eventbrite
        # github repos. We'll fail to clone these unless we've added our
        # ssh-keys so their available to vagrant.
        def setup_ssh_keys()
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

        # We store the git commiter details in a file within the vagrant
        # directory. We do this so we're not always prompting a user for their
        # full name and email.  If they don't provide them the first time
        # around, we'll opt them out and never ask them again.
        #
        # :Returns:
        #   - dict of github creds
        def fetch_git_commiter_details_from_file()
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
        def generate_git_commiter_facts(facts)
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
            set_creds = @env[:ui].ask 'Do you ever plan on committing from within your VM?'\
              ' [y/n]: '
            if set_creds == 'y'
              @env[:ui].warn \
                "You'll be prompted to enter your full name and eventbrite email.\n"\
                "We'll set these for you within your vagrant's .gitconfig.\n"\
                "This will avoid accidentally committing code as 'vagrant'.\n"\
                "If you ever want to reset these, remove\n"\
                "#{@vagrant_git_commiter_details} from your vagrant directory.\n"
              full_name = @env[:ui].ask 'Enter your full name: '
              email = @env[:ui].ask 'Enter your eventbrite email: '
            else
              @env[:ui].warn 'Opting out of setting github creds.'
              full_name = ''
              email = ''
            end
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
          facts['github_full_name'] = full_name.gsub("'", "'\\\\''")
          facts['github_email'] = email
        end

        # generate custom facts and add them to our puppet_config if available
        def generate_custom_facts()
          if @puppet_config
            facts = {}
            generate_git_commiter_facts(facts)
            facts.each_pair { |k, v| @env[:ui].success "Creating fact #{k} => #{v}" }
            @puppet_config.facter = @puppet_config.facter.merge(facts)
          end
        end


        def call(env)
          setup_ssh_keys()
          generate_custom_facts()
          @app.call(env)
        end

      end
    end
  end
end
