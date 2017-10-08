#!/usr/bin/osascript

(* Init and common *)
on Tetris()
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
		property glass: {}

		on levelReset()
			set volume output volume volumeMiddle
		end

		on checkDirection()
			set level to output volume of (get volume settings)
			levelReset()
			_sign(level - volumeMiddle)
		end

		on _sign(int)
			if int > 0 then return 1
			if int < 0 then return -1

			0
		end

		set my glass to newGlass(¬
			glassWidth,¬
			glassHeight,¬
			screenCenter - (glassWidth div 2) * blockSize,¬
			minimalY,¬
			blockSize¬
		)

		tell glass to drawBorder()

		levelReset()

		repeat
			set figure to newFigure(me, screenCenter - blockSize, minimalY)
			tell Figure to move(0, 0)

			repeat
				delay GAMEDELAY
				set sx to checkDirection()

				set obj to figure's check(sx, 1, glass)

				if obj is "space" then
					tell figure to move(sx, 1)
				else if obj is "wall" then
					tell figure to move(0, 1)
				else if {"bottom", "block"} contains obj then
					tell glass to place(figure's getVisibleBlocks())
					exit repeat
				end
			end
		end
	end
end

(* Glass *)
on newGlass(width, height, sx, sy, blockSize)
	set blank to {}
	repeat height times
		set row to {}
		repeat width times
			set row to row & {false}
		end

		set blank to blank & {row}
	end

	script Glass
		property content: blank

		on toGlassX(rx)
			return 1 + (rx - sx) div blockSize
		end

		on toGlassY(ry)
			return 1 + (ry - sy) div blockSize
		end

		on place(figure)
			repeat with fi in figure
				set item toGlassX(x of fi) of item toGlassY(y of fi) of my content to v of fi
			end
		end

		on drawBorder()
			repeat with step from 0 to height - 1
				set r to blockSize div (1.2 + (step mod 2) / 5)

				set y to sy + step * blockSize

				newBlock(r, sx - blockSize, y)
				newBlock(r, sx + width * blockSize, y)
			end

			set y to sy + height * blockSize

			repeat with step from -1 to width
				set r to blockSize div (1.2 + (step mod 2) / 5)

				newBlock(r, sx + step * blockSize, y)
			end
		end

		on isOccupied(x, y)
			set cell to item toGlassX(x) of item toGlassY(y) of content
			return cell is not false
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

	Block
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

	set half to (glassWidth of tetris div 2) * blockSize

	set minx to screenCenter of tetris - half
	set maxx to screenCenter of tetris + half - blockSize
	set maxy to (glassHeight of tetris - 1) * blockSize + minimalY

	set tetris to null

	set fig to some item of figures
	set res to {}

	repeat with ith from 1 to length of fig
		set {cx, cy} to fig's item ith
		set block to {{¬
			x: cx * blockSize + x,¬
			y: cy * blockSize + y,¬
			v: false¬
		}}

		set res to res & block
	end

	script Figure
		property figure: res
		on move(dx, dy)
			repeat with fi in figure
				set nx to x of fi + dx * blockSize
				set ny to y of fi + dy * blockSize

				if ny ≥ minimalY then
					if v of fi is false then
						set v of fi to newBlock(blockSize, nx, ny)
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

		on check(dx, dy, glass)
			repeat with fi in figure
				if v of fi is not false then
					set nx to x of fi + dx * blockSize
					set ny to y of fi + dy * blockSize

					if nx < minx or nx > maxx then
						return "wall"
					end

					if ny < minimalY or ny > maxy then
						return "bottom"
					end

					if glass's isOccupied(nx, ny) then
						return "block"
					end
				end
			end

			"space"
		end

		on getVisibleBlocks()
			set res to {}

			repeat with fi in figure
				if v of fi is not false then
					set res to res & {fi}
				end
			end

			res
		end
	end
end

tell Tetris() to run
