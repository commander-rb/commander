# frozen_string_literal: true

##
# Strips a class of (almost) all its instance methods, leaving it as a
# near-blank slate. Mixed into Commander::Command::Options so that
# +method_missing+ can treat arbitrary option names as accessors without
# clashing with methods Ruby defines on every object (e.g. +send+, +type+).
module Blank
  ##
  # Undefines every instance method on +base+ except those beginning with
  # a double underscore and +object_id+, which are kept so the resulting
  # object remains minimally usable (e.g. for +__send__+ and identity checks).

  def self.included(base)
    base.class_eval do
      instance_methods.each { |m| undef_method m unless m =~ /^__|object_id/ }
    end
  end
end
