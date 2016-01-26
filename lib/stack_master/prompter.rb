module StackMaster
  module Prompter
    def ask?(question)
      StackMaster.stdout.print question
      answer = if ENV['STUB_AWS']
        ENV['ANSWER']
      else
        begin
          STDIN.getch.chomp
        rescue Errno::ENOTTY
          ENV['ANSWER'] || 'y'
        end
      end
      StackMaster.stdout.puts
      answer == 'y'
    end
  end
end
