module VagrantPlugins
  module Ebcommon
    class Config < Vagrant.plugin(2, :config)
      # include any attributes we need
      # ie:
      # attr_accessor :some_val

      def initialize
        # default any values we're collecting to UNSET_VALUE
        # ie:
        # @some_val = UNSET_VALUE
      end

      def finalize!
        # finalize any values we need (set defaults)
        # ie:
        # @some_val = 'default' if @some_val == UNSET_VALUE
      end

    end
  end
end
