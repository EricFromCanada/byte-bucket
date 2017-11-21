-- 
-- Arranges windows for specified applications across two screens.
-- Useful when plugging in an external display, as all app windows will remain on the primary display. Currently supports only two connected displays.
--
-- built-in: the display listed first in system_profiler's output
-- external: a second display that can be unplugged
-- primary: the display with the menu bar, as set in System Preferences > Displays
-- secondary: the display without the menu bar
--

(*** SETTINGS ***)

-- edit these lists to your liking; accepted position values are "top", "middle", or "bottom" for y and "left", "center", or "right" for x

-- the apps listed here will be moved to the built-in display
property windowPositionsBuiltIn : {Â
	{appName:"Notes"}, Â
	{appName:"Mail"} Â
		} -- last item can't have a trailing comma

-- the apps listed here will have their windows moved to the specified location on the external display
property windowPositionsExternal : {Â
	{appName:"Firefox", y:"top", x:"right"}, Â
	{appName:"iTunes", y:"bottom", x:"right"}, Â
	{appName:"Safari", y:"top", x:"left"}, Â
	{appName:"TextWrangler", y:"top", x:"center"}, Â
	{appName:"BBEdit", y:"middle", x:"center"}, Â
	{appName:"Terminal", y:"bottom", x:"left"}, Â
	{appName:"Xcode", y:"bottom", x:"right"} Â
		} -- last item can't have a trailing comma

(*** LOGIC ***)

-- size of entire destkop, with origin at top left of primary display
property allBounds : {}
tell application "Finder"
	set allBounds to bounds of window of desktop
end tell

-- a list of resolution pairs for each connected display
-- we don't use the values for the built-in display, which for Retina displays does not indicate the actual resolution currently used
property allResolutions : {}
set allResolutions to {}
repeat with p in paragraphs of Â
	(do shell script "system_profiler SPDisplaysDataType | awk '/Resolution:/{ printf \"%s %s\\n\", $2, $4 }'")
	set allResolutions to allResolutions & {{word 1 of p as number, word 2 of p as number}}
end repeat
if (count of allResolutions) is not 2 then
	display dialog "Two connected displays are currently required." with icon caution buttons {"Rats"} default button 1
	return
end if

-- if the menu bar is on the external display, there's no need to convert relative coordinates to absolutes
property primaryDisplay : 0
set pfl to do shell script "system_profiler SPDisplaysDataType"
set tid to text item delimiters
set text item delimiters to "Displays:"
set pfl to text item 3 of pfl
if pfl contains "Mirror: On" then
	display dialog "Displays cannot be mirrored." with icon caution buttons {"Darn"} default button 1
	return
end if
set text item delimiters to "Mirror:"
repeat with i from 1 to count of pfl's text items
	set aDisplay to pfl's text item i
	if aDisplay contains "Main Display: Yes" then
		set primaryDisplay to i
	end if
end repeat
set text item delimiters to tid

-- consider the external display as a 3 x 3 grid and use top, middle, bottom, left, center, right to refer to the origin of each square
to makeRelativeValue from relativeTerm on screenNum
	if screenNum is 1 and relativeTerm ­ "top" then
		return 40 -- just put all apps on the built-in screen in the same spot
	end if
	if relativeTerm = "top" then
		return 0
	else if relativeTerm = "middle" then
		return (item 2 of item 2 of allResolutions) / 3 as integer
	else if relativeTerm = "bottom" then
		return (item 2 of item 2 of allResolutions) / 2 as integer
	else if relativeTerm = "left" then
		return 0
	else if relativeTerm = "center" then
		return (item 1 of item 2 of allResolutions) / 4 as integer
	else if relativeTerm = "right" then
		return (item 1 of item 2 of allResolutions) / 2 as integer
	end if
end makeRelativeValue

-- convert coordinates for the secondary display to be relative to the coordinates of the entire desktop
to makeAbsoluteXY from relativeX by relativeY on screenNum
	if primaryDisplay is screenNum then -- the requested display is the primary display
		set _x to relativeX
		set _y to relativeY
	else
		if (item 1 of allBounds < 0) then -- secondary display's left edge is to the left of the primary
			set _x to (item 1 of allBounds) + relativeX
		else -- secondary display's left edge is to the right of the primary
			set _x to ((item 3 of allBounds) - (item 1 of item 2 of allResolutions) + relativeX)
		end if
		if (item 2 of allBounds < 0) then -- secondary display's top edge is above the primary
			set _y to (item 2 of allBounds) + relativeY
		else -- secondary display's top edge is below the primary
			set _y to ((item 4 of allBounds) - (item 2 of item 2 of allResolutions) + relativeY)
		end if
	end if
	return {_x, _y}
end makeAbsoluteXY

-- move all windows of an app to either the built-in display or the specified square of the external display
to moveWindows of anApp to relativeY at relativeX on screenNum
	set absoluteXY to (makeAbsoluteXY from Â
		(makeRelativeValue from relativeX on screenNum) by (makeRelativeValue from relativeY on screenNum) on screenNum)
	tell application "System Events" to set isRunning to (exists process anApp)
	if isRunning then
		tell application "System Events"
			set isVisible to (visible of process anApp)
			try
				set frontmost of process anApp to true -- force switch to space occupied by application
				set visible of process anApp to true
			end try
		end tell
		delay 0.4 -- allow setting window positions to work
		tell application "System Events" to tell process anApp
			try
				set numWindows to count windows -- window count via System Events works for non-scriptable applications
				repeat with i from 1 to numWindows
					set position of window i to absoluteXY -- position of window is only settable in current space via System Events
					set item 1 of absoluteXY to (item 1 of absoluteXY) + 100 -- tile additional application windows horizontally
				end repeat
				set visible to isVisible
			end try
		end tell
	end if
end moveWindows

-- remember and return to the current application after moving windows
tell application "System Events" to set currentApp to name of first process where it is frontmost
repeat with i in windowPositionsBuiltIn
	moveWindows of (appName of i) to "top" at "left" on 1
end repeat
repeat with j in windowPositionsExternal
	moveWindows of (appName of j) to (y of j) at (x of j) on 2
end repeat
tell application currentApp to activate
