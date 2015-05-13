class Player
	
	@MIN_HEALTH = 14

  def play_turn(warrior)
		@warrior = warrior
		
		feel_environement
		
		take_action
  end
	
	protected
	
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
		@ticking_around = @spaces.select{|u| u.ticking? }
		puts "Ticking around #{@ticking_around.inspect}"
		
		@enemies_near = @directions.select{|d| @warrior.feel(d).enemy? }
		puts "Enemies near #{@enemies_near.inspect}"
		@empties_near = @directions.select{|d| @warrior.feel(d).empty? and not @warrior.feel(d).stairs?}
		puts "Empties near #{@empties_near.inspect}"
		@captives_near = @directions.select{|d| @warrior.feel(d).captive? }
		puts "Captives near #{@captives_near.inspect}"		
		@stairs_near = @directions.select{|d| @warrior.feel(d).stairs? }
		puts "Stairs near #{@stairs_near.inspect}"
		@ticking_near = @directions.select{|d| @warrior.feel(d).ticking? }
		puts "Ticking near #{@ticking_near.inspect}"
	end
	
	def take_action
		if @ticking_near.any? or @ticking_around.any?
			@MIN_HEALTH = 6
		end
		
		return move_to victory if @spaces.empty?
		return rest if should_rest? and not (@ticking_near.any? or @ticking_around.any?)
		return take_shelter if must_rest? and not (@ticking_near.any? or @ticking_around.any?)
		return deactive_bomb if @ticking_near.any? or @ticking_around.any?
		return bind_enemy if @enemies_near.any? and @enemies_near.length > 1
		return rescue_captive if @captives_near.any?
		return attack_enemy if @enemies_near.any? and not @ticking_around.any?
		return move_to next_empty unless (@captives_around.any? or @enemies_around.any?) and @stairs_near.empty?
		return move_to near_captive_around if @captives_around.any?
		return move_to near_enemy_around if @enemies_around.any?
		return move_to @stairs_directions_non_near
	end
	
	private
		def must_rest?
			@warrior.health < @MIN_HEALTH
		end
		
		def should_rest?
			@warrior.health < @MIN_HEALTH && safe_to_rest?
		end
				
		def safe_to_rest?
			true unless @enemies_near.length > 0
		end

		#Action methods
		def move_to(direction)
			puts "Moving warrior to #{direction}"
			@warrior.walk! direction
		end
		
		def rest
			@warrior.rest!
			puts "Warrior rest...new health #{@warrior.health}"
		end
		
		def bind_enemy(direction = nil)
			direction = @enemies_near.last if direction == nil
			puts "Binding enemy in direction #{direction}"
			@warrior.bind! direction
		end
		
		def attack_enemy(direction = nil)
			direction = @enemies_near.last if direction == nil
			@warrior.attack! direction
		end
		
		def rescue_captive
			direction = @captives_near.last
			@warrior.rescue! direction
		end
		
		def next_empty
			next_empty = @empties_near.pop
			puts "Go to next empty #{next_empty}"
			return next_empty
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
		
		def take_shelter
			puts "Go to shelter"
			move_to next_empty
		end
		
		def deactive_bomb
			puts "Deactivate bomb"
			if not @ticking_near.empty?
				direction = @ticking_near.first
				puts "Deactive near bomb in direction #{direction}"
				@warrior.rescue! direction
			elsif not @ticking_around.empty?
				direction = near_ticking_around
				puts "Looking for the bomb around in direction #{direction}"
				if @enemies_near.any? and @enemies_near.length > 1
					puts "Go to Bind enemy"
					bind_enemy
				elsif @warrior.feel(direction).enemy?
						puts "Enemy in direction #{direction}. Attack!"
						attack_enemy direction
				else					
					move_to direction
				end
				#return move_to direction unless @warrior.feel(direction).enemy?
				#return bind_enemy direction if @enemies_near.any? and @enemies_near.length > 1
				#return attack_enemy direction
			end
		end
		
		def near_ticking_around
			puts "Go to next ticking around"
			@warrior.direction_of @ticking_around.last
		end
end
