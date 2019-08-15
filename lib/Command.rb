require 'ruby-mud'



class Command
  
  @@commands = Array.new
  attr_accessor :regex, :command, :exec_while_sleeping

  
  
  def Commands.commands
    @@commands
  end
  
  #
  # Checks if the character can actually perform the command
  #
  
  
  def validate character
    if character.sleeping? && !exec_while_sleeping
      character.puts "Oi, you can't do that until you wake up."
      return false
    end
    return true
  end
  
  
  #
  # Defines what command was used by the player and perfomrs it.
  #
  def Command.load
    command = YAML::load_file('lib/commands.yaml')
    command.each { |cmd|
      @@commands.push cmd
      require "lib/commands/#{cmd.command}.rb"
      Player.send :include, self.class.const_get(cmd.command.to_s.capitalize)
    }
  end
  
end