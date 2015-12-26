module Commander
  class Loader
    def self.instance
      @singleton ||= new
    end

    def self.with_command_context(&block)
      instance.with_command_context(&block)
    end

    def self.load_file(fn)
      instance.load_file(fn)
    end

    def self.load_files(fns)
      instance.load_files(fns)
    end

    # Temporarily defines a `command` method on the top-level Object class
    # so that we can load files (rather than eval them) and have the DSL
    # syntax remain the same, forwarding the call along to the Runner instance.
    def with_command_context(&block)
      return if !block_given?

      Object.class_eval do
        def command(*args, &block)
          Runner.instance.command(*args, &block)
        end
      end

      yielded = yield

      Object.class_eval do
        undef_method :command
      end

      yielded
    end

    def load_file(fn)
      with_command_context do
        load fn
      end
    end

    def load_files(fns)
      with_command_context do
        fns.each { |fn| load fn }
      end
    end

  end
end
