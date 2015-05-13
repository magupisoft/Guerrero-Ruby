class Player
	
	MIN_HEALTH = 14

  def play_turn(warrior)
		@warrior = warrior
		
		feel_environement
		
		take_action
		
		#	if should_rest?(warrior)
		#		puts "it should rest! Warrior.Health = #{warrior.health}"
		#		warrior.rest!			
		#	elsif enemies_around?(warrior)
		#		puts "Enemies around \##{@nearby_enemies_count} in last direction #{@direction}"
		#		if @nearby_enemies_count > 1
		#			puts "Bind near enemy in #{@direction}"
		#			warrior.bind! @direction
		#		elsif @distant_enemies_count > 0
		#			warrior.direction_of
		#		else
		#			warrior.attack! @direction
		#		end
		#	elsif can_rescue?(warrior)				
		#		warrior.rescue! @direction unless warrior.feel(@direction).enemy?
		#	elsif has_to_attack?(warrior)
		#			warrior.attack! @direction
		#	else
		#			warrior.walk! warrior.direction_of_stairs unlessenemies_around?(warrior)
#			end
#		else
#			warrior.walk! warrior.direction_of_stairs
#		end
		
		@last_health = warrior.health
  end
	
	def feel_environement
		@directions = %w(forward backward left right).map(&:to_sym) #Ruby1.9.3
		#@direction ||= :forward
		@spaces = @warrior.listen
		
		@enemies_around = @spaces.select{|u| u.enemy? }
		puts "Enemies around #{@enemies_around.inspect}"
		@empties_around = @spaces.select{|u| u.empty? and not u.stairs? }
		puts "Empties around #{@empties_around.inspect}"
		@captives_around = @spaces.select{|u| u.captive? }
		puts "Captives around #{@captives_around.inspect}"
		
		
		@enemies_near = @directions.select{|d| @warrior.feel(d).enemy? }
		puts "Enemies near #{@enemies_near.inspect}"
		@empties_near = @directions.select{|d| @warrior.feel(d).empty? }
		puts "Empties near #{@empties_near.inspect}"
		@captives_near = @directions.select{|d| @warrior.feel(d).captive? }
		puts "Captives near #{@captives_near.inspect}"
	end
	
	def take_action
		return move_to victory if @spaces.empty?
		
		return rest if should_rest?
		return bind_enemy if @enemies_near.any? and @enemies_near.length > 1
		return attack_enemy if @enemies_near.any?
		return rescue_captive if @captives_near.any?
		return move_to next_empty unless @captives_around.any? || @enemies_around.any?
		return move_to near_captive_around if @captives_around.any?
		return move_to near_enemy_around if @enemies_around.any?
	end
	
	private
				
		def can_rescue?(warrior)
			@DIRECTIONS.each do |direction|
				if warrior.feel(direction).captive?
					@direction = direction
					return true
				end
			end
			
			return false
		end
		
		def should_rest?
			@warrior.health < MIN_HEALTH && safe_to_rest?(@warrior)
		end
				
		def safe_to_rest?(warrior)
			true unless @enemies_near.length > 0
		end

		#Action methods
		def move_to(direction = @direction)
			puts "Moving warrior to #{direction}"
			@warrior.walk! direction
		end
		
		def rest
			@warrior.rest!
			puts "Warrior rest...new health #{@warrior.health}"
		end
		
		def bind_enemy
			direction = @warrior.direction_of @enemies_near.last
			@warrior.bind! direction
		end
		
		def attack_enemy
			direction = @enemies_near.last
			@warrior.attack! direction
		end
		
		def rescue_captive
			direction = @captives_near.last
			@warrior.rescue! direction
		end
		
		def next_empty
			puts "Go to next empty"
			@empties_near.last
		end
		
		def near_captive_around
			puts "Go to next captive around"
			@warrior.direction_of @captives_around.last
		end
		
		def near_enemy_around
			puts "Go to next enemy around"
			@warrior.direction_of @enemies_around.last
		end
		
		def victory
			@warrior.direction_of_stairs 
		end
end
