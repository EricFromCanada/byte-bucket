-- Convert an XML dump from editme.com's Export Site module into separate Markdown files using Pandoc.
-- Attachments need to be exported separately into an "assets/uploads" folder within the output folder.

try
	set pandocBin to (do shell script "PATH=/usr/local/bin:$PATH which pandoc") as text
on error
	tell me to error "pandoc is required."
end try

set xmlFile to POSIX path of (choose file of type {"xml"} with prompt "Select EditMe XML file")
set outputFolderPath to POSIX path of (choose folder with prompt "Select output folder")

tell application "System Events"
	tell XML element "pages" of XML element "site" of contents of XML file xmlFile
		set thePageElements to every XML element whose name = "page"
		repeat with a from 1 to (count of thePageElements)
			set theCurrentPageElement to item a of thePageElements
			tell theCurrentPageElement
				
				set thePageName to value of XML element "name"
				set thePageTitle to value of XML element "title"
				if thePageTitle is missing value then
					set thePageTitle to thePageName
				end if
				set thePageDate to value of XML element "date"
				if value of XML element "content" is missing value then
					set thePageContent to " "
				else
					set thePageContent to my replaceText(value of XML element "content", "&" & "nbsp;", " ")
				end if
				
				if XML element "attachments" is not missing value then
					tell XML element "attachments"
						set theAttachments to (every XML element whose name = "attachment")
						repeat with b from 1 to (count of theAttachments)
							set theCurrentAttachment to item b of theAttachments
							tell theCurrentAttachment
								set theName to value of XML element "name"
								set theDescription to value of XML element "description"
								if theDescription is missing value then
									set theDescription to theName
								end if
								set thePageContent to thePageContent & "<hr>" & return & "<a href=\"/assets/uploads/" & theName & "\">" & theDescription & "</a>" & return
							end tell
						end repeat
					end tell
				end if
				
				if XML element "comments" exists then
					tell XML element "comments"
						set theComments to (every XML element whose name = "comment")
						repeat with c from 1 to (count of theComments)
							set theCurrentComment to item c of theComments
							tell theCurrentComment
								set thePageContent to thePageContent & "<hr>" & return & value of XML element "user" & " " & value of XML element "date" & ": " & value of XML element "content" & return
							end tell
						end repeat
					end tell
				end if
				
				set outputText to "---" & return & "title: " & my replaceText(thePageTitle, ":", " -") & return
				set outputText to outputText & "date: " & thePageDate & return & "---" & return & return
				set outputText to outputText & "# " & thePageTitle & return & return
				set outputText to outputText & (do shell script "echo " & quoted form of thePageContent & " | " & pandocBin & " -f html -t markdown_github | iconv -f MACROMAN -t UTF-8") & return
				set outputText to my replaceText(outputText, return, linefeed)
				
				set outputTextFile to outputFolderPath & thePageName & ".md"
				try
					-- just in case a file pointer got left open
					close access outputTextFile
				end try
				
				set fp to open for access outputTextFile with write permission
				write outputText to fp
				close access fp
				
			end tell
		end repeat
	end tell
end tell

on replaceText(subject, find, replace)
	set prevTIDs to text item delimiters of AppleScript
	set text item delimiters of AppleScript to find
	set subject to text items of subject
	set text item delimiters of AppleScript to replace
	set subject to "" & subject
	set text item delimiters of AppleScript to prevTIDs
	
	return subject
end replaceText
