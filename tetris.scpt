#!/usr/bin/osascript

(* Init *)

property BLOCKSIZE: 10
property VOLUMECENTER: 50
property GLASSWIDTH: 10
property GLASSHEIGHT: 20
property GAMEDELAY: 1

global MINIMALY
set MINIMALY to checkMinimalY()

global SCREENCENTER
set SCREENCENTER to getCenterOfScreen()

on init()
	levelReset()
end

on levelReset()
	set volume output volume VOLUMECENTER
end

(* Screen *)

on getScreenResolution()
	tell application "Finder"
		set screen_resolution to bounds of window of desktop
	end

	return screen_resolution
end

on getCenterOfScreen()
	return getScreenResolution()'s item 3 div 2
end

on checkMinimalY()
	set wid to createNewBlock(0, 0)
	tell application "TextEdit"
		set coords to bounds of 1st window whose id is wid
		close 1st window
	end

	return coords's item 2
end

(* Keyboard *)

on sign(int)
	if int > 0 then return 1
	if int < 0 then return -1

	return 0
end

on checkDirection()
	set level to output volume of (get volume settings)
	levelReset()
	return sign(level - VOLUMECENTER)
end

(* Block *)

on moveBlock(wid, x, y)
	tell application "TextEdit"
		set the index of 1st window whose id is wid to 1
		set the bounds of 1st window to {x, y, (x + BLOCKSIZE), (y + BLOCKSIZE)}
	end
end

on closeBlock(wid)
	tell application "TextEdit"
		close 1st window whose id is wid
	end
end

on createNewBlock(x, y)
	tell application "TextEdit"
		activate
		make new document at the front
		set wid to id of front window
	end

	moveBlock(wid, x, y)

	return wid
end

(* Figures *)
on translateFigure(figure)
	set res to {}

	repeat with ith from 1 to length of figure
		set cell to figure's item ith
		set cell to {{¬
			x: (cell's item 1) * BLOCKSIZE + SCREENCENTER,¬
			y: (cell's item 2) * BLOCKSIZE + MINIMALY,¬
			v: false¬
		}}

		set res to res & cell
	end

	return res
end

on moveFigure(figure, sx, sy)
	repeat with fi in figure
		set nx to x of fi + sx * BLOCKSIZE
		set ny to y of fi + sy * BLOCKSIZE

		if nx ≥ 0 and ny ≥ MINIMALY then
			if v of fi is false then
				set v of fi to createNewBlock(nx, ny)
			else
				moveBlock(v of fi, nx, ny)
			end
		end

		set x of fi to nx
		set y of fi to ny
	end

	return figure
end

on checkFigure(figure, sx, sy)
	set leftLimit to SCREENCENTER - GLASSWIDTH * BLOCKSIZE
	set rightLimit to SCREENCENTER + GLASSWIDTH * BLOCKSIZE
	set downLimit to GLASSHEIGHT * BLOCKSIZE + MINIMALY

	repeat with fi in figure
		set nx to x of fi + sx * BLOCKSIZE
		set ny to y of fi + sy * BLOCKSIZE

		if nx ≤ leftLimit or nx ≥ rightLimit or ny ≥ downLimit then
			return false
		end
	end

	return true
end

on initFigure(figure)
	return moveFigure(figure, 0, 0)
end

on clearFigure(figure)
	repeat with fi in figure
		if v of fi is not false then
			closeBlock(v of fi)
		end
	end
end

on randomFigure()
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

	return translateFigure(some item of figures)
end

(* Main *)

set figure to initFigure(randomFigure())
repeat
	delay GAMEDELAY

	set sx to checkDirection()

	if checkFigure(figure, sx, 1) then
		set figure to moveFigure(figure, sx, 1)
	else
		exit repeat
	end
end


