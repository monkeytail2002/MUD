#
# This class is for combat when it is initiated
#

class Combat
  include Singleton
  attr_accessor :lock
  
  #
  # Defines the process for fighting.  First line checks for all characters fighting.  Second line sets the combat round.
  # Third line sets the status for the characters fighting.  Fourth line is for Player vs Player combat.
  #
  
  def process
    characters_fighting = World.instance.characters.find_all { |character| !character.fighting.nil? }
    characters_fighting.each { |character| combat_round(character) }
    characters_fighting.each { |character| character.puts character.fighting.status if character.fighting }
    characters_fighting.each { |character| character.prompt if character.is_a? Player }
  end
  
  #
  #Defines the combat round for the attacker
  #
  
  def combat_round attacker
    @lock.synchronize {
      
    # Checks if the attacker is fighting or not
   
      if attacker.fighting.nil?
        return
      end
      victim = attacker.fighting
      attacker.puts "\n"
      victim.puts "\n"
      
      #Checks if the victim is fighting.  If not then the victim is set to the attacker (so it states something like "You hit yourself")
     
      if victim.fighting.nil?
        victim.fighting = attacker
      end
      
      #Checks is the attack hits the target.
     
      if !does_hit? attacker, victim
        attacker.puts "Your attack slices through the air, missing your opponent."
        return
      end
      
      #Sets the text shown in game when a hit happens for both the attacker and the victim.
      
      damage = attacker.dam_dice.roll
      attacker.puts "Your #{damage.to_damage_string[0]} #{attacker.hit_word} #{damage.to_damage_string[1]} #{victim.name}!"
      victim.puts "#{attacker.name}'s #{attacker.hit_word} #{damage.to_damage_string[1]} you!".capitalize
      victim.injure damage
    }
  end
  
 #
 # Defines whether the attacker manages to hit the AC of the user. 
 # Originally based on THAC0, I changed it to modern meet or beat.
 # 
  
  def does_hit? attacker, victim
    return rand(21) >= attacker.to_hit_ac - victim.ac
  end
  
  #
  # This basically monitors the combat.

  #
  def CombatManager.begin_monitoring
    CombatManager.instance.lock = Mutex.new
    Thread.start do
      loop{
        CombatManager.instance.process
        sleep 2
      }
    end
  end
  
end