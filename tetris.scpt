#!/usr/bin/osascript

(* Init and common *)
on newTetris()
	-- Get screen dimension
	tell application "Finder"
		set screenResolution to bounds of window of desktop
	end

	-- Get height of menu bar
	tell application "TextEdit"
		activate
		make new document at the front
		set the bounds of 1st window to {0, 0, 0, 0}
		set coords to bounds of 1st window
		close 1st window
	end

	script Tetris
		property blockSize: 10
		property volumeMiddle: 50
		property screenCenter: screenResolution's item 3 div 2
		property minimalY: coords's item 2
		property glassWidth: 10
		property glassHeight: 20
		property gameDelay: 1

		on init()
			levelReset()
		end

		on levelReset()
			set volume output volume volumeMiddle
		end

		on checkDirection()
			set level to output volume of (get volume settings)
			levelReset()
			return _sign(level - volumeMiddle)
		end

		on _sign(int)
			if int > 0 then return 1
			if int < 0 then return -1

			return 0
		end

		set figure to newFigure(me, screenCenter, 0)

		repeat
			delay GAMEDELAY
			set sx to checkDirection()

			if figure's check(sx, 1, me) then
				tell figure to move(sx, 1)
			else
				return
			end
		end
	end
end

(* Block *)

on newBlock(blockSize, x, y)
	tell application "TextEdit"
		activate
		make new document at the front
		set |id| to id of front window
	end

	script Block
		property wid: |id|

		on destroy()
			tell application "TextEdit"
				close 1st window whose id is wid
			end
		end

		on move(x, y)
			tell application "TextEdit"
				set the index of 1st window whose id is wid to 1
				set the bounds of 1st window to {x, y, (x + blockSize), (y + blockSize)}
			end
		end
	end

	tell Block to move(x, y)

	return Block
end

(* Figures *)

on newFigure(tetris, x, y)
	-- TIJLOSZ
	set figures to {¬
		[[-1, -1], [0, -1], [1, -1], [0, 0]],¬
		[[0, -3], [0, -2], [0, -1], [0, 0]],¬
		[[-1, -1], [-1, 0], [0, 0], [1, 0]],¬
		[[1, -1], [-1, 0], [0, 0], [1, 0]],¬
		[[-1, -1], [-1, 0], [0, 0], [0, -1]],¬
		[[-1, 0], [0, 0], [0, -1], [1, -1]],¬
		[[-1, -1], [0, 0], [0, -1], [1, 0]]¬
	}

	set blockSize to blockSize of tetris
	set minimalY to minimalY of tetris

	set minx to screenCenter of tetris - glassWidth of tetris * blockSize
	set maxx to screenCenter of tetris + glassWidth of tetris * blockSize
	set maxy to glassHeight of tetris * blockSize + minimalY

	set tetris to null

	set fig to some item of figures
	set res to {}

	repeat with ith from 1 to length of fig
		set cell to fig's item ith
		set cell to {{¬
			x: (cell's item 1) * blocksize + x,¬
			y: (cell's item 2) * blocksize + y,¬
			v: false¬
		}}

		set res to res & cell
	end

	script Figure
		property figure: res
		on move(sx, sy)
			repeat with fi in figure
				set nx to x of fi + sx * blockSize
				set ny to y of fi + sy * blockSize

				if ny ≥ minimalY then
					if v of fi is false then
						set v of fi to newBlock(blocksize, nx, ny)
					else
						tell v of fi to move(nx, ny)
					end
				end

				set x of fi to nx
				set y of fi to ny
			end
		end

		on destroy()
			repeat with fi in figure
				if v of fi is not false then
					tell v of fi to destroy()
				end
			end
		end

		on check(sx, sy)
			repeat with fi in figure
				if v of fi is not false then
					set nx to x of fi + sx * blockSize
					set ny to y of fi + sy * blockSize

					if nx ≤ minx or nx ≥ maxx or ny ≤ minimalY or ny ≥ maxy then
						return false
					end
				end
			end

			return true
		end
	end

	tell Figure to move(0, 0)

	return Figure
end

tell newTetris() to run
