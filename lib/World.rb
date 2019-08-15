class World
  include Singleton
  attr_accessor :rooms, :races, :mobiles, :players, :classes
  STAT_RANGE = (0..25)
  
  
  #
  # Defines the player stats.  Based on basic D&D/Pathfinder stats.
  #
  
  def stats
    [:str, :con, :dex, :wis, :int, :cha, :hp, :mana]
  end
  
  #
  # Defines what loads from where.
  # Also sets the area where users can donate gear for others to take at any point.  Star Wars reference because why not?
  #
  
  def load
    @rooms = Hash[*Room.find(:all).map { |r| [r.id,  r] }.flatten]
    @races = YAML::load(File.read("#{File.dirname(__FILE__)}/races.yaml"))
    @classes = YAML::load(File.read("#{File.dirname(__FILE__)}/classes.yaml"))
    @players = Array.new
    @mobiles = Array.new  
    pit = Item.find_by_name("The Sarlacc's gaping maw")
    unless pit.nil? || !pit.contents.empty?
      Item.find(:all).each { |i| pit.contents.push i }
      pit.save
    end
  end
  
  #
  # Defines who the characters are.
  #
  
  def characters
    [*@players + @mobiles]
  end
  
  #
  # Defines character description when a player uses whois/finger/whatever I decide to call the command to figure out who someone is.
  #
  
  def describe_who_to character
    players.each do |char|
      character.puts "[#{char.level} #{char.race.first(3).capitalize} #{char.character_class.first(3).capitalize}] #{char.short_description}"
    end
    character.puts "#{players.length} players found."
  end
    
  #
  # Defines what a character gains in hp when con is increased
  #
  
  def hp_gain_for_con con
    return STAT_RANGE.interpolate(-4, 8)[con]
  end
  
  
end