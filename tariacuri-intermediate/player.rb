class Player
	
	MIN_HEALTH = 14

	def initialize
	 @DIRECTIONS = %w(forward backward left right).map(&:to_sym)
	end
	
  def play_turn(warrior)
		@last_health ||= warrior.health
		@direction ||= :forward
		
			if should_rest?(warrior)
				puts "it should rest! Warrior.Health = #{warrior.health}"
				warrior.rest!			
			elsif enemies_around?(warrior)
				puts "Enemies around \##{@enemy_count} in last direction #{@direction}"
				if @enemy_count > 1
					puts "Bind enemy in #{@direction}"
					warrior.bind! @direction
				else
					warrior.attack! @direction
				end
			elsif can_rescue?(warrior)				
				warrior.rescue! @direction unless warrior.feel(@direction).enemy?
			elsif has_to_attack?(warrior)
					warrior.attack! @direction
			else
						warrior.walk! warrior.direction_of_stairs unless enemies_around?(warrior)
			end
		
 		@last_health = warrior.health
  end
	
	private
		def has_to_attack?(warrior)
			if enemies_around?(warrior)
				puts "Attack #{direction}"
				return true
			end
			
			return false
		end
		
		def can_rescue?(warrior)
			@DIRECTIONS.each do |direction|
				if warrior.feel(direction).captive?
					@direction = direction
					return true
				end
			end
			
			return false
		end
		
		def should_rest?(warrior)
			warrior.health < MIN_HEALTH && safe_to_rest?(warrior)
		end
				
		def safe_to_rest?(warrior)
		    true unless enemies_around?(warrior)
		end

		def enemies_around?(warrior)
				@enemy_count = 0
				@DIRECTIONS.each do |direction|
					if warrior.feel(direction).enemy?
						@enemy_count += 1
						@direction = direction
					end
				end
				return true if @enemy_count > 0
				return false
		end
end
