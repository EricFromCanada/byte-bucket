# Script to close the Safari Web Inspector.
# Use a utility like Butler to bind to a separate keystroke, such as Cmd-Opt-Shift-I.
# Obsolete with Safari 6, in which the keystroke finally toggles the inspector.

if version of application "Safari" starts with "5" then
	tell application "System Events"
		click UI element 1 of group 1 of group 1 of UI element 1 of scroll area 1 of group 1 of group 1 of group 3 of window 1 of application process "Safari"
	end tell
end if
