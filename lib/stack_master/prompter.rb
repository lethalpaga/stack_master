module StackMaster
  module Prompter
    def ask?(question)
      StackMaster.stdout.print question
      answer = if ENV['STUB_AWS'] || !StackMaster.interactive
        StackMaster.default_answer
      else
        begin
          STDIN.getch.chomp
        rescue Errno::ENOTTY
          StackMaster.default_answer
        end
      end
      StackMaster.stdout.puts
      answer == 'y'
    end
  end
end
