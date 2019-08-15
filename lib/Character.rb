module Character
  attr_accessor :socket_client
  attr_accessor :room
  attr_accessor :fighting
  attr_accessor :position
  
  
  #
  # Sets it up so that worn items can affect stats.
  #
  [:str, :con, :dex, :wis, :int, :cha].each do |stat|
    eval %Q{
      def current_#{stat}
        worn_#{stat}_affects = equipment.inject(0) { |sum, item| sum + item.aff_#{stat} }
        #{stat} + worn_#{stat}_affects
      end
    }
  end
  
  #
  # Sets it up so that weapons affect ac
  #
  
  [:ac_pierce, :ac_bash, :ac_slash, :ac_exotic].each do |ac|
    eval %Q{
        def #{ac}
          equipment.inject(0) { |sum, item| sum + item.#{ac} }
        end
    }
  end
  
  #
  # Defines inventory slots
  #
  
  def inventory
    slots.find_by_name('inventory').contents
  end
  
  #
  # Defines equipment slots
  #
  
  def eq_slots
    slots.find(:all).reject {|slot| slot.name == 'inventory' }.sort_by{ |slot| slot.name }
  end
  
  
  #
  # Defines a characters equipment
  # 
  
  def equipment
    eq_slots.collect {|slot| slot.contents }.flatten
  end
  
  #
  # Defines what is worn by a character
  # 

  def worn slot
    slots.find_by-name(slot).contents
  end
  
  #
  # Defines basic AC.  In modern D&D/Pathfinder this starts at 10 usually before mods.  I am not doing THAC0.  Fuck THAC0
  #
  
  def AC
    return 10
  end
  
  #
  # Defines the damage that is done per hit based on what is wielded.
  #
  
  def dam_dice
    return naked_dam_dice if worn('wielded').empty?
    return worn('wielded').first.attack.dice!
  end
  
  #
  # Initialises a character.
  #
  
  def initialize_character
    self.position = "standing"
    if slots.empty?
      Slot.equipment_slots.each { |slot| slots << Slot.new(:name => slot, :max => 1) }
      slots << Slot.new(:name => 'inventory')
    end
  end
  
  
  #
  # Defines a characters movements and what shows when a character leaves/enters a room
  #
   
  def move_to (room, options=())
    options = {
      :leave_description => 'vanishes before your eyes'
    }.merge(options)
    
    if room.nil
      return
    end
    
    if !@room.nil?
      @room.characters.delete self
      @room.characters.each { |character| character.notify "#{name} #{options[:leave_description]}"}
    end
    room.characters.each { |character| character.notify "#{name} has arrived." }
    room.characters.push.self
    @room = room
  end
  
  #
  # Defines the amount of XP until the next level.  For all those XP hounds out there.
  #
  
  def tnl
    return per_level * (level) - xp
  end
  
  
  #
  # Defines how much hp you lose when injured
  #
  
  def injure hp
    return self.hp -= hp
    die if !is_alive?
  end
  
  #
  # This is a fun one in MUD's.  When you die you leave a corpse behind with all your shit in it.  It's lootable too, so better collect fast.
  # This defines the corpse of a character
  #
  
  def create_corpse
    corpse = Item.new(:name => 'corpse', :short_description => "#{name}'s corpse lies here, freshly slain.", :takeable => true, :keywords=>'corpse', :item_type=>'container')
    corpse.save
    inventory.each { |item| corpse.contents << item }
    inventory.delete_all
    corpse
  end
  
  #
  # Defines healing
  #
  
  def heal hp
    self.hp = [self.hp + hp, max_hp].min
  end
  
  #
  # Opposite end of the spectrum here as it defines the ultimate wage of sin, death.
  #
  
  def die
    puts "A large figure in a black robe holding a scythe grins at you. Well, he'll always grin for his head is a skull with two eyes glowing blue. He states to you: I TAKE LIFE AS IT COMES. IN THIS CASE I AM TAKING YOURS. YOU ARE DEAD."
    room.load_items << create_corpse
    self.fighting = nil
    World.instance.characters.find_all { |char| char.fighting == self }.each {|char| char.killed_target}
  end
  
  #
  # Defines the end of combat if you kill your target
  #
    
  def killed_target
    puts "#{fighting.name} has been slain.  Messily.  There's blood everywhere you animal."
    self.fighting = nil
  end
  
  #
  # Defines a characters health status
  #
  
  def status
    (case (self.hp.to_f / self.max_hp) * 100
      when 100; "#{name} is in excellent condition."
      when 90...100; "#{name} has some scrapes.  Take some paracetamol"
      when 75...90; "#{name} has some small wounds and bruises.  Better see a nurse."
      when 50...75; "#{name} has quite a few wounds.  Ok ignore the nurse and see a doctor."
      when 30...50; "#{name} has some big nasty wounds and scratches.  Tis but a scratch!"
      when 15...30; "#{name} looks pretty hurt. Was that your arm flying off there?"
      when 0...15; "#{name} is in awful condition.  Someone call it, we can do no more for #{name}"
      else "#{name} is bleeding to death.  Wont somebody think of the children?  They shouldn't see someone so badly mauled."
      end).capitalize
  end
  
  
  #
  # Defines the word used for an attack based on what is wielded.
  #
  
  def hit_word
    worn('wielded').empty? ? naked_attack_word : worn('wielded').first.attack.word
  end
  
  
  #
  #  Checks to see if character is alive
  #
  
  def is_alive?
    return self.hp > 0
  end
  
  
  #
  # Checks if the character can move or if they are fighting
  #
  
  def can_move?
    return @fighting.nil?, "In the middle of a fight?"
  end
  
  #
  # defines attempts to move
  #
  
  def attempt_move_to (room, options={})
    can_move, reason = can_move?
    if !can_move
      puts reason
      return
    end
    move_to room, options
  end
  
  
  #  
  # Defines the xp received for killing a victim.
  #
  
  def cal_xp victim
    return 0 if victim.level < level - 10
    (victim.level - (level - 10)) * 15
  end
  
  
  #
  # Defines the health returned for every tick based on sleeping/standing etc.
  #
  
  def tick_hp
    base_heal = (5+level)
    base_heal *= 2 if position == 'sleeping'
    base_heal
  end
  
  
  #
  # Defines if character can go to sleep or not.
  #
  
  def attempt_go_to_sleep
    if fighting
      puts "They say suicide is painless.  Trying to sleep in combat will show you that it's not."
      return
    end
    self.position = 'sleeping'
    puts "1 sheep.  2 sheep.  3 sheep. 4 sheep... zzzzzz"
  end
  
  
  #
  # Defines the action of standing
  #    
  
  def stand
    if !sleeping?
      puts "You're already standing numbnuts."
      return
    end
    self.position = 'standing'
    puts "You stand up."
  end
  
  
  #
  # Just sets out if character is sleeping
  #
  
  def sleeping?
    position == "sleeping"
  end
  
  #
  # Displays character description
  #
  
  def decribe_to character
    character.puts description
  end
  
  
   
end