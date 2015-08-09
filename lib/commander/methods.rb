module Commander
  module Methods
    include Commander::UI
    include Commander::UI::AskForClass
    include Commander::Delegates

    if $stdin.tty?
      screen_width = HighLine::SystemExtensions.terminal_size.first rescue 80
      if screen_width >= 5
        $terminal.wrap_at = screen_width - 5
      end
    end
  end
end
