require "curses"
include Curses

class Board < Array

	def initialize
		super(10){Array.new(10)}
	end

	def populate
		(0..9).each do |row|
			self[row].each_index do |col|
				Piece.new(:X, [row, col], self) if [0,2].include?(row) && (col%2)!=0
				Piece.new(:X, [row, col], self) if [1,3].include?(row) && col%2==0
				Piece.new(:O, [row, col], self) if [6,8].include?(row) && (col%2)!=0
				Piece.new(:O, [row, col], self) if [7,9].include?(row) && col%2==0
			end
		end
	end

	def to_s(cursor = nil)
		print_string = "  0 1  2 3  4 5  6 7  8 9\n"
		self.each_with_index do |row, row_index|
			print_string << "#{row_index}"
			row.each_with_index do |tile, col_index|
        if !cursor.nil? && row_index == cursor[0] && col_index == cursor[1]
          print_string << " \u2713"
          next
        end
        if tile.nil?
          print_string << " \u2745"
        else
          print_string << " #{tile.to_s}"
        end
			end
			print_string << "\n"
		end
    print_string
	end

	#Easy access to Board elements
	def [](pos)
		if pos.is_a?(Array)
			return self[pos[0]][pos[1]]
		else
			super(pos)
		end
	end

	def []=(pos, value)
		if pos.is_a?(Array)
			return self[pos[0]][pos[1]] = value
		else
			super(pos,value)
		end
	end
end

class Piece
	attr_accessor :pos, :mark
	VECTORS = [[1,1],[1,-1],[-1,1],[-1,-1]]

	def initialize(mark, pos, board)
		@mark, @pos, @board, @promoted = mark, pos, board, false
		@board[pos] = self
	end

	def out_of_bounds?(pos)
		!pos.all?{|coord| coord.between?(0,9)}
	end

	def make_move(pos)
		if can_jump_to.include?(pos)
			jump(pos)
      true
		elsif can_slide_to.include?(pos)
			@board[@pos] = nil
			@board[pos] = self
			@pos = pos
			try_promote
			true
		else
			return false
		end
	end

	def legal_moves
		(can_jump_to + can_slide_to)
	end

	def jump(pos)
		until can_jump_to.empty?
			while pos.nil? || !can_jump_to.include?(pos)
				puts "can jump again to: #{can_jump_to}"
				pos = gets.chomp.split(',').map(&:to_i)
			end
			if can_jump_to.include?(pos)
				@jumped_pos = average(pos,@pos)
				@board[@jumped_pos] = nil
				@board[@pos] = nil
				@board[pos] = self
				@pos = pos
				try_promote
				true
			end
		end
	true
	end

	def try_promote
		if @pos[0] == 0 && @mark == :X
			@promoted = true
		elsif @pos[0] == @board.length && @mark == :O
			@promoted = true
		end
	end

	def average(pos1,pos2)
		[(pos1[0]+pos2[0])/2, (pos1[1]+pos2[1])/2]
	end

	#returns possible moves piece can slide to
	def can_slide_to
		candidates = VECTORS.map{|vec| [vec[0]+@pos[0],vec[1]+@pos[1]]}
		candidates.reject!{|candidate| out_of_bounds?(candidate)}
		candidates.select!{|candidate| @board[candidate].nil?}
		candidates.select!{|candidate| candidate[0]>@pos[0]} if !@promoted && @mark == :X
		candidates.select!{|candidate| candidate[0]<@pos[0]} if !@promoted && @mark == :O
		candidates
	end

	#returns possible moves piece can jump to
	def can_jump_to
		candidates = VECTORS.map{|vec| [(vec[0]*2+@pos[0]),(vec[1]*2+@pos[1])]}
		candidates.reject!{|candidate| @board[average(candidate, @pos)].nil? || @board[average(candidate,@pos)].mark == @mark}
		candidates.reject!{|candidate| out_of_bounds?(candidate)}
		candidates.select!{|candidate| @board[candidate].nil?}
		candidates.select!{|candidate| candidate[0]>@pos[0]} if !@promoted && @mark == :X
		candidates.select!{|candidate| candidate[0]<@pos[0]} if !@promoted && @mark == :O
		candidates
	end

	def to_s
		return "\u2661" if @mark == :X
		return "\u2606" if @mark == :O
	end
end

class Game
	def initialize
		@board = Board.new
		@board.populate
    @cursor_pos = [4,4]
	end
	def run
		[:O,:X].cycle do |mark|

			system('clear')
			print @board.to_s(@cursor_pos)
			turn(mark)
		end
	end
	def turn(player)
		begin
			puts "Player #{player}.  Enter piece pos!"
			piece_pos = get_pos(@cursor_pos)#gets.chomp.split(',').map(&:to_i)
			piece = @board[piece_pos]
			raise "No piece there" if piece.nil?
			raise "Not your piece" if piece.mark != player
			puts "can_jump_to: #{piece.can_jump_to}"
			puts "can_slide_to: #{piece.can_slide_to}"

			puts "Player #{player}.  Enter move pos!"
			move_pos = get_pos(piece_pos.dup)#gets.chomp.split(',').map(&:to_i)
      @cursor_pos = move_pos.dup
			raise "Can't move there" unless piece.make_move(move_pos)
		rescue => exception
			puts exception.message
			retry
		end
	end

  def get_pos(cursor_pos = [4,4])
    while true
      begin
        system("stty raw -echo")
        str = STDIN.getc
      ensure
        system("stty -raw echo")
      end
      if str == 'q'
        exit
      elsif str == ' '
        system('clear')
        print @board
        p cursor_pos
        return cursor_pos
      elsif str == 'w'
        cursor_pos[0] -= 1 if cursor_pos[0] > 0
      elsif str == 's'
        cursor_pos[0] += 1 if cursor_pos[0] < @board.length-1
      elsif str == 'a'
        cursor_pos[1] -= 1 if cursor_pos[1] > 0
      elsif str == 'd'
        cursor_pos[1] += 1 if cursor_pos[1] < @board.length-1
      end

      system('clear')
      print @board.to_s(cursor_pos)
      p cursor_pos
    end
  end
end



game = Game.new
game.run
