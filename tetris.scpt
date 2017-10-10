#!/usr/bin/osascript

property blockSize: 10
property minimalY: null
property screenCenter: null
property glassWidth: 10
property glassHeight: 20
property gameDelay: .3
property volumeMiddle: 50

(* Init and common *)
on Tetris()
	-- Get screen dimension
	tell application "Finder"
		set screenResolution to bounds of window of desktop
	end

	set screenCenter to screenResolution's item 3 div 2

	-- Get height of menu bar
	tell application "TextEdit"
		activate
		make new document at the front
		set the bounds of 1st window to {0, 0, 0, 0}
		set coords to bounds of 1st window
		close 1st window
	end

	set minimalY to coords's item 2

	script Tetris
		property glass: {}

		on levelReset()
			set volume output volume volumeMiddle without muted
		end

		on checkDirection()
			set level to output volume of (get volume settings)
			levelReset()
			_sign(level - volumeMiddle)
		end

		on checkRotate()
			return output muted of (get volume settings)
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
			minimalY¬
		)

		tell glass to drawBorder()

		levelReset()

		set startX to screenCenter - blockSize

		repeat
			set figure to newFigure(startX, minimalY, null)
			tell figure to init()

			repeat
				delay GAMEDELAY

				if checkRotate() then
					tell figure to rotate()
				end

				set sx to checkDirection()

				set obj to figure's check(sx, 1, glass)

				if obj is "space" then
					tell figure to moveBy(sx, 1)
				else if obj is "wall" then
					tell figure to moveBy(0, 1)
				else if {"bottom", "block"} contains obj then
					if obj is "block" and figure's check(0, 1, glass) is "space" then
						tell figure to moveBy(0, 1)
					else
						if obj is "block" and not moved of figure then
							-- Game over
							return
						end

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
end

(* Glass *)
on newGlass(width, height, sx, sy)
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
			repeat with blk in figure
				set item toGlassX(rx of blk) of item toGlassY(ry of blk) of my content to blk
			end
		end

		on drawBorder()
			repeat with step from 0 to height - 1
				set r to blockSize div (1.2 + (step mod 2) / 5)

				set y to sy + step * blockSize

				newBlock(sx - blockSize, y, r)
				newBlock(sx + width * blockSize, y, r)
			end

			set y to sy + height * blockSize

			repeat with step from -1 to width
				set r to blockSize div (1.2 + (step mod 2) / 5)

				newBlock(sx + step * blockSize, y, r)
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
						tell blk to moveByBlock(0, 1)
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

on newBlock(x, y, |size|)
	script Block
		property wid: null
		property visible: false
		property rx: x
		property ry: y

		on create()
			tell application "TextEdit"
				make new document at the front
				set my wid to id of front window
			end

			set my visible to true
		end

		on destroy()
			if wid isn't null then
				tell application "TextEdit"
					close 1st window whose id is wid
				end
			end
		end

		on moveTo(x, y)
			if y ≥ minimalY then
				if wid is null then create()

				tell application "TextEdit"
					set the bounds of 1st window whose id is wid to {x, y, (x + |size|), (y + |size|)}
				end
			end

			set my rx to x
			set my ry to y
		end

		on moveByBlock(dx, dy)
			moveTo(rx + dx * |size|, ry + dy * |size|)
		end
	end

	tell Block to moveTo(x, y)

	Block
end

(* Figures *)

on newFigure(x, y, figNum)
	set figures to {¬
		["T", [-1, -1], [0, -1], [1, -1], [0, 0]],¬
		["I", [0, -3], [0, -2], [0, -1], [0, 0]],¬
		["J", [-1, -1], [-1, 0], [0, 0], [1, 0]],¬
		["L", [1, -1], [-1, 0], [0, 0], [1, 0]],¬
		["O", [-1, -1], [-1, 0], [0, 0], [0, -1]],¬
		["S", [-1, 0], [0, 0], [0, -1], [1, -1]],¬
		["Z", [-1, -1], [0, 0], [0, -1], [1, 0]]¬
	}

	set half to (glassWidth div 2) * blockSize

	set minx to screenCenter - half
	set maxx to screenCenter + half - blockSize
	set maxy to (glassHeight - 1) * blockSize + minimalY

	set tetris to null

	script Figure
		property figure: {}
		property raw: {}
		property moved: false
		property type: null
		property degree: 0

		on init()
			if figNum is null then
				set fig to some item of figures
			else
				set fig to item figNum of figures
			end

			set my raw to items 2 thru 5 of fig
			set my type to first item of fig

			repeat with |item| in translate(raw, x, y)
				set [rx, ry] to |item|
				set my figure to figure & newBlock(rx, ry, blockSize)
			end
		end

		on translate(fig, x, y)
			set res to {}

			repeat with |item| in fig
				set [cx, cy] to |item|
				set [cx, cy] to rotateOne(cx, cy)

				set end of res to [cx * blockSize + x, cy * blockSize + y]
			end

			res
		end

		on rotateOne(x, y)
			if degree is 0 then return [x, y]
			if degree is 90 then return [-y, x]
			if degree is 180 then return [-x, -y]

			[y, -x]
		end

		on rotate()
			if type is "O" then return

			if degree is less than 270 then
				set my degree to degree + 90
			else
				set my degree to 0
			end

			repeat with nth from 1 to 4
				if item nth of raw is [0, 0] then
					set blk to item nth of figure
					set x to rx of blk
					set y to ry of blk

					exit repeat
				end
			end

			set coords to translate(raw, x, y)
			repeat with nth from 1 to length of figure
				set [rx, ry] to item nth of coords

				(item nth of figure)'s moveTo(rx, ry)
			end
		end

		on moveBy(dx, dy)
			if dx ≠ 0 or dy ≠ 0 then
				repeat with blk in figure
					tell blk to moveByBlock(dx, dy)
				end

				set my moved to true
			end
		end

		on destroy()
			repeat with blk in figure
				tell blk to destroy()
			end
		end

		on check(dx, dy, glass)
			repeat with blk in figure
				if visible of blk then
					set nx to (rx of blk) + dx * blockSize
					set ny to (ry of blk) + dy * blockSize

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

			repeat with blk in figure
				if visible of blk then
					set res to res & blk
				end
			end

			res
		end
	end
end

tell Tetris() to run
