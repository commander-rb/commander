# frozen_string_literal: true

##
# Adds Object#get_binding, used by HelpFormatter::Context to capture a
# target object's binding for evaluation inside an ERB help template.
class Object
  ##
  # Return the current binding.
  def get_binding
    binding
  end
end
