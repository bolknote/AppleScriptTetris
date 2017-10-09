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
		property gameDelay: .3
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

		set startX to screenCenter - blockSize

		repeat
			set figure to newFigure(me, startX, minimalY, null)
			tell figure to move(0, 0)

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

					set |line| to glass's detectLines()

					repeat until |line| is false
						glass's collapseLine(|line|)
						set |line| to glass's detectLines()
					end

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
		set blankRow to {}
		repeat width times
			set blankRow to blankRow & {false}
		end

		set blank to blank & {blankRow}
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

		on detectLines()
			repeat with nth from 1 to length of content
				if false is not in item nth of content then
					return nth
				end
			end

			false
		end

		on collapseLine(ith)
			repeat with idx from ith - 1 to 1 by -1
				repeat with blk in content's item idx
					if contents of blk is not false then
						tell blk to moveDown()
					end
				end
			end

			repeat with blk in content's item ith
				if contents of blk is not false then
					tell blk to destroy()
				end
			end

			set blankRow to {}
			repeat width times
				copy false to end of blankRow
			end

			if ith is 1 then
				set newcontent to {blankRow}
			else
				set newcontent to {blankRow} & items 1 thru (ith - 1) of content
			end

			if ith is not length of content then
				set newcontent to newcontent & items (ith + 1) thru end of content
			end

			copy newcontent to my content
		end

		on debug()
			log ""
			repeat with |line| in content
				set out to {}
				repeat with blk in |line|
					if contents of blk is false then
						copy "_____" to end of out
					else
						copy text -5 thru -1 of ("00000" & wid of blk) to end of out
					end
				end

				log out
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
				set the bounds of 1st window whose id is wid to {x, y, (x + blockSize), (y + blockSize)}
			end
		end

		on moveDown()
			tell application "TextEdit"
				set {x, y} to (get bounds of 1st window whose id is wid)
			end

			move(x, y + blockSize)
		end
	end

	tell Block to move(x, y)

	Block
end

(* Figures *)

on newFigure(tetris, x, y, figNum)
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

	if figNum is null then
		set fig to some item of figures
	else
		set fit to item figNum of figures
	end

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
