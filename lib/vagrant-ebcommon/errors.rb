module VagrantPlugins
  module Ebcommon
    module Errors

      class VPNRequired < Vagrant::Errors::VagrantError
        error_key('vpn_required')
      end

    end
  end
end

