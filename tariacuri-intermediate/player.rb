#Manuel Gutiérrez Pineda
#@magupisoft 2015
class Player

	EXTREME_MIN_HEALTH ||= 3

  def play_turn(warrior)
		@warrior = warrior

		print_status_title
		feel_environement
		
		print_action_title
		take_action
  end
	
	protected
	
		#########################
		###   steps methods    ##
		#########################
		def feel_environement
			@directions = %w(forward backward left right).map(&:to_sym) #Ruby1.9.3
			@min_health = 8			
			@recent_binded_direction ||= {}
			
			@spaces = @warrior.listen
		
			@enemies_around = @spaces.select{|u| u.enemy? }
			puts "-Enemies around #{@enemies_around.inspect}"
			@empties_around = @spaces.select{|u| u.empty? and not u.stairs? }
			puts "-Empties around #{@empties_around.inspect}"
			@captives_around = @spaces.select{|u| u.captive? }
			puts "-Captives around #{@captives_around.inspect}"
			@ticking_around = @spaces.select{|u| u.ticking? }
			puts "-Ticking around #{@ticking_around.inspect}"
		
			@enemies_near = @directions.select{|d| @warrior.feel(d).enemy? }
			puts "-Enemies near #{@enemies_near.inspect}"
			@empties_near = @directions.select{|d| @warrior.feel(d).empty? and not @warrior.feel(d).stairs?}
			puts "-Empties near #{@empties_near.inspect}"
			@captives_near = @directions.select{|d| @warrior.feel(d).captive? }
			puts "-Captives near #{@captives_near.inspect}"		
			@stairs_near = @directions.select{|d| @warrior.feel(d).stairs? }
			puts "-Stairs near #{@stairs_near.inspect}"
			@ticking_near = @directions.select{|d| @warrior.feel(d).ticking? }
			puts "-Ticking near #{@ticking_near.inspect}"
		
			@look_ahead = @warrior.look :forward
			@look_behind = @warrior.look :backward
			@look_left = @warrior.look :left
			@look_right = @warrior.look :right
									
			if @ticking_around.any?
				@distance_of_ticking_captives = @warrior.distance_of @ticking_around.first
				puts "-Distance of ticking captive #{@distance_of_ticking_captives}"
			else
				@distance_of_ticking_captives = -1
			end

			if exist_ticking?
				@min_health = 6 unless sludge_is_obstructing?
				@min_health = 4 if sludge_is_obstructing?
				@min_health = 8 if @enemies_near.length > 2
				@min_health = 12 if not exist_ticking? and not @enemies_near.length > 2
			end
			puts "-Min health \##{@min_health}"
			
		end
	
		def take_action		
			return move_to stairs								if @spaces.empty?
			return rest													if decide_to_rest?
			return take_shelter									if decide_to_take_shelter?
			return deactivate_bomb							if exist_ticking? and @distance_of_ticking_captives <= 2 
			return bind_enemy										if (@enemies_near.any? and @enemies_near.length > 1) 
			return detonate_bomb								if decide_to_detonate_bomb_action? 
			return rest													if decide_to_rest_necessarily?			
			return rescue_captive 							if @captives_near.any? and not exist_ticking?
			return attack_enemy 								if decide_to_attack_enemy_action? 
			return move_to near_empty 					if not (@captives_around.any? or @enemies_around.any?) and @stairs_near.empty?
			return move_to near_captive_around 	if @captives_around.any? and not exist_ticking?
			return move_to near_enemy_around 		if @enemies_around.any? and not exist_ticking?
			return move_to near_ticking_around	if exist_ticking?
			return move_to @stairs_directions_non_near
		end
	
	private
	
		#########################
		### Decisition methods ##
		#########################
		def must_scape?
			if @enemies_around.empty? & @enemies_near.empty?
				return false 
			end
			
			if exist_ticking? and (@warrior.feel(near_ticking_around).empty? or @warrior.feel(near_ticking_around).captive?)
				return false 
			end

			if @warrior.health <= @min_health
					return @warrior.health <= @min_health
			end
		end

		def should_rest?
			to_scape = must_scape? & safe_to_rest?
			ticking_captives = @distance_of_ticking_captives > 2
			ticking_captives = @distance_of_ticking_captives == -1 if ticking_captives == false
			
			return to_scape & ticking_captives
		end

		def must_rest?
			if @went_to_shelter
				 @went_to_shelter = false
				 return true
			end
			
			if exist_ticking?
				if (@warrior.feel(near_ticking_around).empty? or @warrior.feel(near_ticking_around).captive?) and not @warrior.health <= EXTREME_MIN_HEALTH
					return false 
				end
			end
			
			if @warrior.health <= EXTREME_MIN_HEALTH or should_rest?
					return true 
			end

			return false
		end

		def safe_to_rest?
			@enemies_near.length == 0
		end

		def exist_ticking?
			@ticking_near.any? or @ticking_around.any?
		end

		def enemies_look?
			enemies_ahead? or enemies_behind? or enemies_left? or enemies_right?
		end
		
		def enemies_ahead?
			@look_ahead.any? and @look_ahead.count{ |a| a.enemy? } >= 2
		end
		
		def enemies_behind?
			@look_behind.any? and @look_behind.count{ |a| a.enemy? } >= 2
		end
		
		def enemies_left?
			@look_left.any? and @look_left.count{ |a| a.enemy? } >= 2
		end
		
		def enemies_right?
			@look_right.any? and @look_right.count{ |a| a.enemy? } >= 2
		end
		
		def sludge_is_obstructing?
			obsctruct = false
			
			enemies = surrounded_enemies
			obsctruct = false if enemies.empty? or enemies.nil?
			
			enemies.each do |e|
				 if near_ticking_around == @warrior.direction_of(e)
					 obsctruct = true
					 break
				end
			end
			
			puts "\tsludge is obstructing? #{obsctruct}"
			return obsctruct
		end
		
		# Decition steps 
		def decide_to_rest?
			(should_rest? and not exist_ticking?) or
			(exist_ticking? and must_rest? and safe_to_rest?)
		end
		
		def decide_to_take_shelter?
			(must_scape? and not exist_ticking?) or 
			(must_scape? and exist_ticking? and @enemies_near.length >=2)
		end
		
		def decide_to_detonate_bomb_action?
			(enemies_look? and 
				(@enemies_near.any? or surrounded_enemies.length > 0) and
			 	(@distance_of_ticking_captives == -1 or @distance_of_ticking_captives > 2)) or
			(enemies_look? and 
				(@enemies_near.any? or surrounded_enemies.length > 0) and
			 	exist_ticking? and @distance_of_ticking_captives > 2)
		end
						
		def decide_to_attack_enemy_action?
			(@enemies_near.any? and not exist_ticking?)		or
			 (exist_ticking? and sludge_is_obstructing?)	or
			 (exist_ticking? and 
			 								surrounded_enemies.length > 1 and 
															@warrior.feel(near_ticking_around).enemy?)
		end
		
		def decide_to_rest_necessarily?
			must_rest? and 
			((not exist_ticking? and surrounded_enemies.length == 0) or
			 			(not exist_ticking? and @distance_of_ticking_captives > 2)) and
				not sludge_is_obstructing?
		end
		#########################
		###   action methods   ##
		#########################
		def move_to(direction)
			puts "\tMoving warrior to #{direction}"
			@warrior.walk! direction
		end
		
		def rest
			@warrior.rest!
		end
		
		def bind_enemy(direction = nil)
			puts "\tbinding enemy"
			
			direction = @enemies_near.last if direction == nil
			puts "\tBinding enemy in direction #{direction}"
			@recent_binded_direction[@warrior.feel(direction)] = direction.to_s
			@warrior.bind! direction
			puts "\tBind direction #{@recent_binded_direction.inspect}"
		end
		
		def attack_enemy(direction = nil)
			puts "\tattacking enemy"
			if direction != nil
				return	@warrior.attack! direction
			end
			
			if not @enemies_near.empty?
				direction = @enemies_near.last if direction == nil
				@warrior.attack! direction
			else
				enemies = surrounded_enemies
					if enemies.length > 0
						direction = near_ticking_around
						if @warrior.feel(direction).to_s.downcase.start_with?('s')
								@warrior.attack! direction
						else
							direction = @warrior.direction_of(enemies.first)
							@warrior.attack! direction
						end
					else
						direction = @warrior.direction_of(enemies.first)
						@warrior.attack! direction
					end
			end
		end
		
		def rescue_captive
			puts "\trescueing captive"
			
			direction = @captives_near.first
			return @warrior.rescue! direction if @recent_binded_direction.empty?
			return @warrior.rescue! direction if surrounded_enemies.length == 0
			
			real_captive_found = false
			@captives_near.each do |direction|				
					warrior_feel = @warrior.feel(direction)
					if not warrior_feel.nil? and warrior_feel.to_s.downcase.start_with?('c')
						puts "\tRescueing a real captive in #{direction}"
						@warrior.rescue! direction
						real_captive_found = true						
						break
					end
			end
			
			if not real_captive_found
				@captives_near.each do |direction|
					binded = @recent_binded_direction.select{ |key,value| 
							@warrior.direction_of(key) == direction 
						} unless @recent_binded_direction.empty? or not @recent_binded_direction.any?
					
						if binded != nil and not binded.empty?					
							warrior_feel = @warrior.feel(@warrior.direction_of(binded.keys[0]))
							if not warrior_feel.nil? and warrior_feel.to_s.downcase.start_with?('s')
								puts "\tCaptive is in fact an enemy. Attack! in #{direction}"
								attack_enemy direction
	
								@recent_binded_direction.delete_if do |key, value|
									 @warrior.direction_of(key) == direction
								end
								break
							end
						end
				end
			end
		end

		def near_empty
			near_empty = @empties_near.pop
			puts "\tGo to next empty #{near_empty}"
			return near_empty
		end

		def near_captive_around
			puts "\tGo to next captive around"
			@warrior.direction_of @captives_around.last
		end

		def near_enemy_around
			puts "\tGo to next enemy around"
			@warrior.direction_of @enemies_around.last
		end

		def near_ticking_around
			@warrior.direction_of @ticking_around.first
		end

		def stairs
			@warrior.direction_of_stairs 
		end

		def take_shelter
			puts "\ttaking shelter"
			if @empties_near.any?
				puts "\tGo to shelter"
				@went_to_shelter = true
				move_to near_empty
			end
		end

		def deactivate_bomb
			puts "\tDeactivating bomb"
			
			if not @ticking_near.empty?
				direction = @ticking_near.first
				puts "\tDeactivate near bomb in direction #{direction}"
				@warrior.rescue! direction
			elsif not @ticking_around.empty?
				direction = near_ticking_around
				puts "\tLooking for the bomb around in direction #{direction}"
				
				if @enemies_near.any?
					if enemies_look? and @distance_of_ticking_captives > 2
						detonate_bomb
					elsif @enemies_near.length > 1
						puts "\tGo to Bind enemy"
						bind_enemy
					else
						puts "\tEnemy in direction #{direction}. Attack!"
						attack_enemy
					end					
				elsif @warrior.feel(direction).enemy?
					if enemies_look? and @distance_of_ticking_captives > 2
						detonate_bomb
					else
						puts "\tEnemy in direction #{direction}. Attack!"
						attack_enemy direction
					end
				elsif must_scape?
					rest
				else					
					if @warrior.feel(direction).to_s.downcase.start_with?('s')
						@empties_near.each do |e|
							if @warrior.feel(e).empty?
								return move_to e
							end
						end
					else
						move_to direction
					end
				end
			end
		end

		def detonate_bomb
			puts "\tdetonating bomb"
			
			if not must_scape?
				enemies = @look_ahead.select{ |s| s.enemy? }
				if enemies.empty?
					enemies = @look_behind.select{ |s| s.enemy? }
				end
				if enemies.empty?
					enemies = @look_left.select{ |s| s.enemy? }
				end
				if enemies.empty?
					enemies = @look_right.select{ |s| s.enemy? }
				end
				
				if not enemies.empty?
					direction = @warrior.direction_of enemies.first
					puts "\tDetonate bomb in direction #{direction}"
					@warrior.detonate! direction
				else
					rest
				end
			else
				take_shelter
			end
		end

		def surrounded_enemies	
			enemies = []
			@directions.each do |direction|
				if @warrior.feel(direction).enemy? 
					enemies << @warrior.feel(direction)
				end
				
				binded = @recent_binded_direction.select{ |key,value| 
						@warrior.direction_of(key) == direction 
					} unless @recent_binded_direction.empty? or not @recent_binded_direction.any?
	
				if binded != nil and not binded.empty?
					warrior_feel = @warrior.feel(@warrior.direction_of(binded.keys[0]))
					enemies << binded.keys[0] if not warrior_feel.nil? and warrior_feel.to_s.downcase.start_with?('s')
				end
			end
			
			puts "\tSurrounded by enemies #{enemies.inspect}"
			return enemies
		end

		#########################
		###    util methods    ##
		#########################
		def opposite_direction(direction)
			case direction
			when 'forward'
				return 'backward'
			when 'backward'
				return 'forward'
			when 'right'
				return 'left'
			when 'left'
				return 'right'
			end
		end
		
		def print_status_title
				puts ("=" * 15) + " STATUS " + ("=" * 15)		
		end	
		
		def print_action_title
				puts "=" * 15 + " ACTIONS " + ("=" * 15)		
		end
end