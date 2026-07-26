# frozen_string_literal: true

module Commander
  ##
  # = Methods
  #
  # The primary entry point for adding Commander's DSL to an object.
  # Bundles Commander::UI (terminal output/prompting helpers),
  # Commander::UI::AskForClass (the +ask_for_*+ family of methods), and
  # Commander::Delegates (the +command+/+program+/+run!+ DSL) into a
  # single mixin. <tt>require 'commander/import'</tt> includes this into
  # the top-level Object; embedders typically include it directly instead.
  #
  # When connected to a sufficiently wide terminal, also configures
  # HighLine to wrap output five columns short of the terminal width.
  module Methods
    include Commander::UI
    include Commander::UI::AskForClass
    include Commander::Delegates

    if $stdin.tty? && (cols = HighLine.default_instance.output_cols) >= 40
      HighLine.default_instance.wrap_at = cols - 5
    end
  end
end
