module Commander
  module Patches
    module HelpFormatterBinding
      def get_binding(additional = {})
        bnd = @target.instance_eval { binding }.tap do |bind|
          decorate_binding(bind)
        end
        additional.each do |k, v|
          bnd.local_variable_set(k, v)
        end
        bnd
      end
    end
  end
end
