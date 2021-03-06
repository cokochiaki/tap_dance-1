require 'rubygems/user_interaction'

module TapDance
  class UI
    attr_reader :log

    def warn(message, newline = nil)
    end

    def debug(message, newline = nil)
    end

    def trace(message, newline = nil)
    end

    def error(message, newline = nil)
    end

    def info(message, newline = nil)
    end

    def confirm(message, newline = nil)
    end

    def detail(message, newline = nil)
    end

    def debug?
      false
    end

    def ask(message)
    end

    class Shell < UI
      LEVELS = %w(silent error warn detail confirm info debug)

      attr_writer :shell

      def initialize(options = {})
        if options["no-color"] || !STDOUT.tty?
          Thor::Base.shell = Thor::Shell::Basic
        end
        @shell = Thor::Base.shell.new
        @level = ENV['DEBUG'] ? "debug" : "info"
      end

      def info(msg, newline = nil)
        tell_me(msg, nil, newline) if level("info")
      end

      def confirm(msg, newline = nil)
        tell_me(msg, :green, newline) if level("confirm")
      end

      def detail(msg, newline = nil)
        tell_me(msg, :cyan, newline) if level("detail")
      end

      def warn(msg, newline = nil)
        tell_me(msg, :yellow, newline) if level("warn")
      end

      def error(msg, newline = nil)
        tell_me(msg, :red, newline) if level("error")
      end

      def debug(msg, newline = nil)
        tell_me(msg, nil, newline) if level("debug")
      end

      def debug?
        # needs to be false instead of nil to be newline param to other methods
        level("debug")
      end

      def quiet?
        LEVELS.index(@level) <= LEVELS.index("warn")
      end

      def ask(msg)
        @shell.ask(msg)
      end

      def level=(level)
        raise ArgumentError unless LEVELS.include?(level.to_s)
        @level = level
      end

      def level(name = nil)
        name ? LEVELS.index(name) <= LEVELS.index(@level) : @level
      end

      def trace(e, newline = nil)
        msg = ["#{e.class}: #{e.message}", *e.backtrace].join("\n")
        if debug?
          tell_me(msg, nil, newline)
        elsif @trace
          STDERR.puts "#{msg}#{newline}"
        end
      end

      def silence
        old_level, @level = @level, "silent"
        yield
      ensure
        @level = old_level
      end

    private

      def tell_me(msg, color = nil, newline = nil)
        return if (msg.nil? || msg == "") && newline.nil?
        msg = word_wrap(msg) if newline.is_a?(Hash) && newline[:wrap]
        line = if newline.nil? then [] else [newline] end

        if msg.is_a? ShellResult
          unless msg.out.chomp == ""
            @shell.say(msg.out.chomp, color, *line)
            logger(msg.out.chomp, *line)
          end

          unless msg.err.chomp == ""
            @shell.say(msg.err.chomp, :red)
            logger(msg.err.chomp)
          end
        else
          @shell.say(msg, color, *line)
          logger(msg, *line)
        end
      end

      def logger(message, newline=(message.to_s !~ /( |\t)$/))
        @log ||= ""
        @log << message
        @log << $/ if newline
      end

      def word_wrap(text, line_width = @shell.terminal_width)
        text.split("\n").collect do |line|
          line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
        end * "\n"
      end
    end

    class Logger < Shell

    private

      def tell_me(msg, color = nil, newline = nil)
        if newline.nil?
          logger(msg)
        else
          logger(msg, newline)
        end
      end
    end
  end
end
