class InputParser
  
  #
  #Something has to make sure players don't put in gibberish
  #
  
  def parse(input, character)
    input_cleaned = input.strip.split
    command = input_cleaned.first
    args = input_cleaned.slice(1...input_cleaned.length)
    candidate = Command.commands.find { |cmd| cmd.regex.match(command) }
    if !candidate.nil?
      character.send candidate.command, args if candidate.validate character
    else
      character.puts "Fit's that ya loon?  Ye wanna pump a sheep? Naw?  Well better type clearer next time"
    end
  end
end