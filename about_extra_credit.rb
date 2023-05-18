# EXTRA CREDIT:
#
# Create a program that will play the Greed Game.
# Rules for the game are in GREED_RULES.TXT.
#
# You already have a DiceSet class and score function you can use.
# Write a player class and a Game class to complete the project.  This
# is a free form assignment, so approach it however you desire.
DICE = [
  [
    "┌─────────┐",
    "│         │",
    "│    ●    │",
    "│         │",
    "└─────────┘",
  ],
  [
    "┌─────────┐",
    "│  ●      │",
    "│         │",
    "│      ●  │",
    "└─────────┘",
  ],
  [
    "┌─────────┐",
    "│  ●      │",
    "│    ●    │",
    "│      ●  │",
    "└─────────┘",
  ],
  [
    "┌─────────┐",
    "│  ●   ●  │",
    "│         │",
    "│  ●   ●  │",
    "└─────────┘",
  ],
  [
    "┌─────────┐",
    "│  ●   ●  │",
    "│    ●    │",
    "│  ●   ●  │",
    "└─────────┘",
  ],
  [
    "┌─────────┐",
    "│  ●   ●  │",
    "│  ●   ●  │",
    "│  ●   ●  │",
    "└─────────┘",
  ]
]

DIE_HEIGHT = DICE[1].size
DIE_WIDTH = DICE[1][0].size

DIE_FACE_SEPARATOR = " "

class Player
  def initialize
    @name = ""
    @dice = []
    @scoring_dice = []
    @score = 0
    @score_this_turn = 0
    @carry_points = 0
  end
  
  def name(name)
    @name = name
  end
  
  def player_name
    @name
  end
  
  def new_turn
    @score += @score_this_turn
    @scoring_dice = []
    roll 5
    score
    check_for_all_scoring
  end
  
  def roll_again
    # Re-roll the un-scoring dice
    $printer.add_message "Rolling " + (5 - @scoring_dice.size).to_s + " un-scoring dice: \t" + (@dice - @scoring_dice).to_s
    score_before_new_roll = @score_this_turn
    roll 5 - @scoring_dice.size
    
    # if the roll added new scoring dice then this roll was a success, do nothing
    if score_before_new_roll == score # otherwise this is a bust
      $printer.add_message "\r\nOH NO! That's a bust!!"
      @dice = []
      @score_this_turn = 0
      @carry_points = 0
      $printer.output_text
    else
      check_for_all_scoring
    end
  end
  
  def check_for_all_scoring
    if @scoring_dice.size == 5 # check if we have 5 scoring dice
      $printer.add_message "\r\nALL FIVE DICE ARE SCORING!! "
      $printer.output_text
      $printer.add_message "Rolling all dice again.."
      @carry_points = @score_this_turn
      @score_this_turn = 0
      new_turn
    end
  end
  
  def dice
    @dice
  end
  
  def scoring_dice
    @scoring_dice
  end
  
  def total_score
    @score
  end
  
  def score_this_turn
    @score_this_turn + @carry_points
  end
  
  def bank
    @score += @score_this_turn + @carry_points
    @score_this_turn = 0
    @carry_points= 0
    @scoring_dice = []
  end
  
  def score
    score = 0
    @scoring_dice = []
    if @dice == nil
      return score
    end
    frequencies = @dice.tally
    (1..6).each { |number_on_die|
      occurrences = frequencies[number_on_die]
      if occurrences != nil
        if occurrences < 3
          # * A one (that is not part of a set of three) is worth 100 points.
          if number_on_die == 1
            score += 100 * occurrences
            add_scoring_dice(number_on_die, occurrences)
            # * A five (that is not part of a set of three) is worth 50 points.
          elsif number_on_die == 5
            score += 50 * occurrences
            add_scoring_dice(number_on_die, occurrences)
          end
        else
          # * A set of three ones is 1000 points
          if number_on_die == 1
            score += 1000 + ((frequencies[number_on_die] - 3) * 100)
            add_scoring_dice(number_on_die, occurrences)
            # * A set of three numbers (other than ones) is worth 100 times the number
          elsif number_on_die == 5 # Special case because single 5's count towards score
            score += (100 * number_on_die) + ((frequencies[number_on_die] - 3) * 50)
            add_scoring_dice(number_on_die, occurrences)
          else
            score += 100 * number_on_die
            add_scoring_dice(number_on_die, 3)
          end
        end
      end
    }
    @score_this_turn = score
  end
  
  private
  
  def roll(number_of_dice)
    rolls = []
    (1..number_of_dice).each { rolls.append(rand(1..6)) }
    @dice = @scoring_dice.sort + rolls
    $printer.add_message "New dice rolled are: \t\t" + rolls.to_s
    $printer.add_dice @dice
  end
  
  def add_scoring_dice(number_on_die, occurrences)
    (1..occurrences).each do
      @scoring_dice.append(number_on_die)
    end
  end
end

class Game
  def setup(number_of_players)
    @number_of_players = 0
    @players = Array.new
    
    # Check for bad value
    if number_of_players <= 0
      raise ArgumentError
    end
    # Setup each player with a name from the user
    @number_of_players = number_of_players
    (1..number_of_players).each do |player|
      @players.append(Player.new)
      puts "Please name player " + player.to_s + ": "
      @players[player - 1].name gets.chomp
    end
    $printer.update_standings @players
    true
  end
  
  def play(number_of_players)
    unless setup(number_of_players)
      return
    end
    # Let's play!!
    playing = true
    while playing
      (1..@number_of_players).each do |player|
        @player = @players[player - 1]
        players_turn = true
        $printer.current_player player
        start_new_turn
        
        while players_turn
          # If this player has no score yet
          if @player.total_score == 0
            players_turn = zero_score_round
            unless players_turn
              break
            end
          end
          
          # Otherwise we just display our roll and the menu
          input = menu
          if input.include?("1") # Menu option one, roll again
            players_turn = roll_again
          elsif input.include?("2") # Menu option two, bank
            players_turn = false
            playing = bank # The bank method also checks if a player has won
            unless playing
              end_phase(player)
              return
            end
          elsif input.include?("3") # Menu option three, exit
            return
          else
            $printer.add_message "Invalid menu option, please try again.\r\n"
            $printer.add_dice(@player.dice)
          end
        end
      end
    end
  end
  
  def zero_score_round
    while @player.score_this_turn < 300 && @player.total_score == 0
      $printer.add_message "\r\nScore of at least 300 required to bank..."
      $printer.output_text
      @player.roll_again
      if @player.score_this_turn == 0 # if we bust
        return false # next player's turn
      end
    end
    true
  end
  
  def start_new_turn
    $printer.add_message "Rolling all five dice..."
    @player.new_turn
  end
  
  def menu
    $printer.add_message "\r\nNon-Scoring Dice: " + (@player.dice - @player.scoring_dice).to_s +
                           "\r\nTotal Score: " + @player.total_score.to_s +
                           "\tCurrent Dice Score: " + @player.score_this_turn.to_s
    $printer.output_menu_and_text
    gets.chomp
  end
  
  def roll_again
    @player.roll_again
    if @player.score_this_turn == 0 # if we bust
      false
    else
      true
    end
  end
  
  def bank
    @player.bank
    $printer.update_standings  @players
    if @player.total_score >= 3000
      return false
    end
    true
  end
  
  def end_phase(player)
    $printer.add_message @player.player_name.to_s.upcase + " HAS REACHED 3000 POINTS"
    $printer.add_message "All other players will get one more turn, and the highest score will win\r\n"
    winning_player = @player
    (1..@number_of_players).each do |players_last_turn|
      if player != players_last_turn
        @player = @players[players_last_turn - 1]
        players_turn = true
        
        $printer.current_player players_last_turn
        $printer.add_message "Rolling all five dice..."
        @player.new_turn
        
        while players_turn
          input = menu
          if input.include?("1") # Menu option one, roll again
            players_turn = roll_again
          elsif input.include?("2") # Menu option two, bank
            players_turn = false
            bank
            if @player.total_score > winning_player.total_score
              winning_player = @player
            end
          elsif input.include?("3") # Menu option three, exit
            return
          else
            $printer.add_message "Invalid menu option, please try again.\r\n"
            $printer.add_dice(@player.dice)
          end
        end
      end
    end
    $printer.output_winner winning_player.player_name.to_s.upcase
  end
end

class Pretty_print
  def initialize
    @multiline_message = ""
    @current_player = ""
    @player_standings = ""
  end
  
  def add_message(message_to_add)
    @multiline_message += message_to_add + "\r\n"
  end
  
  def add_dice(dice_values)
    # Generate a list of dice faces from DICE
    dice_faces = []
    
    dice_values.each { |value|
      dice_faces.append(DICE[value-1])
    }
      
    # Generate a list containing the dice faces rows
    dice_faces_rows = []
    (0...DIE_HEIGHT).each { |row_idx|
      row_components = []
      
      dice_faces.each { |die|
        row_components.append(die[row_idx])}
      row_string = ""
      row_components.each { |row_component|
        row_string += " " + row_component}
      @multiline_message += row_string + "\r\n"
    }
  end
  
  def update_standings(players)
    @player_standings = ""
    players.each do |player|
      @player_standings += player.player_name.to_s + "\t\t"
    end
    @player_standings += "\r\n"
    players.each do |player|
      @player_standings += "Score: " + player.total_score.to_s + "\t"
    end
  end
  
  def current_player(player_number)
    @current_player = ""
    spacing_string = ""
    (1...player_number).each do
      spacing_string += "\t\t"
    end
    @current_player += spacing_string + "  ^  \r\n"
    @current_player += spacing_string + " ^-^ \r\n"
  end
  
  def output_text
    output_shared
    puts "Please Press Enter to Continue"
    gets.chomp
    @multiline_message = ""
  end
  
  def output_menu_and_text
    output_shared
    puts "Press 1 to roll again\t Press 2 to bank your score\t Press 3 to exit"
    @multiline_message = ""
  end
  
  def output_winner(winning_player_name)
    puts
    puts "-------------------------------------------------------------------------------------------------------------"
    puts "\r\n\r\n\r\n\t\t\t\t" + winning_player_name + " WINS!!! \r\n\t\t\t\tCONGRATULATIONS !!!\r\n\r\n\r\n\r\n"
    puts "-------------------------------------------------------------------------------------------------------------"
  end
  
  private
  def output_shared
    lines_to_pad = (10-@multiline_message.lines.size)
    if lines_to_pad % 2 != 0 # Odd number of lines to pad
      @multiline_message = "\r\n" + @multiline_message
    end
    
    (1..lines_to_pad/2).each do
      @multiline_message = "\r\n" + @multiline_message + "\r\n"
    end
    puts "\r\n\r\n"
    puts "-------------------------------------------------------------------------------------------------------------"
    puts @player_standings
    puts "-------------------------------------------------------------------------------------------------------------"
    puts @current_player
    puts "-------------------------------------------------------------------------------------------------------------"
    puts @multiline_message +
           "-------------------------------------------------------------------------------------------------------------"
  end
end

$printer = Pretty_print.new

game = Game.new
puts "How many players are there? "
game.play(gets.chomp.to_i)
  