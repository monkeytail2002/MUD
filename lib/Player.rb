require 'active_record'
class Player < ActiveRecord::Base
  include Character
  has_and_belongs_to_many :slots, :class_name=>'Slot', :join_table=>'players_slots'
    
  def short_description
    "#{name}, the #{race} #{character_class}"
  end

  def get_class
    World.instance.classes[character_class]
  end

  def naked_attack_word
    "punch"
  end

  def to_hit_ac
    get_class.to_hit_ac_at_level level
  end

  after_initialize :initialize_character

  def room_description
    short_description + " is lurking in the corner here."
  end

  def move_to (room, options = { })
    if room.nil?
      puts "Does that look like an exit to you?"
      return
    end
    super room, options
    @room.describe_to self
  end

  def puts (*args)
    @socket_client.puts args unless @socket_client.nil?
  end

  def print *args
    @socket_client.print args
  end

  def notify(*args)
    @socket_client.puts unless @socket_client.nil?
    @socket_client.print  args unless @socket_client.nil?
    prompt
  end
  
  def prompt 
    @socket_client.print "\n<#{hp}/#{max_hp}hp #{mana}/#{max_mana}mana #{tnl}tnl> " unless @socket_client.nil?
  end

  def assign_race(race)
    self.race = race
    real_race = World.instance.races[race]
    World.instance.stats.each do |stat| 
      send "#{stat}=".to_sym, real_race.send("start_#{stat}")
    end
    self.max_hp = hp
    self.max_mana = mana
  end

  def matches? input
    name.downcase.start_with? input.downcase
  end

  def naked_dam_dice
    Dice.new(:count => level, :sides=>2, :constant =>0)
  end

  def die
    super 
    move_to World.instance.rooms.first[1], :leave_description => "falls to the floor a bloody mess.  Yup, they're dead."
    self.hp = max_hp
  end

  def check_level
    if tnl <= 0
      self.level +=1
      self.max_hp += (10..15).to_a.rand + World.instance.hp_gain_for_con(con)
      puts "Oooh, look at you reaching level #{level}.  Fancy"
    end
  end

  def killed_target
    xp = (calc_xp fighting).spread
    super
    self.xp += xp
    puts "You feel yourself getting stronger as you slice through what was once a living thing."
    check_level
  end
end