module Commander
  module Patches
    module OptionDefaults
      # I can't remember what this patch does, but I found it in the code
      # base. It is better if this magic is kept separate
      def option(*args, &block)
        default = nil
        args.delete_if do |v|
          if v.is_a?(Hash) && v.key?(:default)
            default = v[:default]
            true
          else
            false
          end
        end
        opt = super
        opt.tap do |h|
          h.merge!( { default: default } ) unless default.nil?
        end
      end
    end
  end
end
