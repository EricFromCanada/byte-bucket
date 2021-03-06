(*
Journler2Blogger 1.5.1
Written by Eric Knibbe, 2008

This script allows posting from Journler directly to Blogger. It relies on the same backend 
used by Blogger's BlogThis! bookmarklet. If you have Markdown.pl or SmartyPants.pl installed 
in your Scripts folder, your path, or in the support folders for BBEdit, TextMate, or 
TextWrangler, they will be applied to your text. Most special characters, if present, will be 
converted to named or numeric entity references before posting.

After showing a preview of the processed text, the script copies it to the clipboard and a 
page is opened in your default browser, into which you paste your entry for posting.

To install, place this file in ~/Library/Scripts/Journler/ and link it to Journler's "Blog" button 
under Preferences > Advanced. In order to use Markdown.pl and SmartyPants.pl, they should 
be in one of the folders listed under pathAdditions, preferably in /Library/Scripts. If either is 
not found, the script skips them silently.

Notes: 
- Posts beyond a certain length will not fit in the preview dialog, although the script will still work. 
- Since Journler entries' "is blogged" attribute cannot be set using Applescript, this 
script instead tags the entry as "Blogged". 
- Blogged entries' Created dates are by default reset to the current date, so Journler lists them in 
the order they were posted.
- Your Blogger blog's "Convert line breaks" setting should be off.

Version history: see Description field
­*)

-- Preferences
property useMarkdown : true
property useSmartyPants : true
property useNamedEntities : true
property setEntryDate : true
property tagAsBlogged : "Blogged"

tell application "Finder" to set homepath to POSIX path of (home as alias)

set pathAdditions to "export PATH=$PATH:" & ¬
	"/Applications/BBEdit.app/Contents/PlugIns/\"Language Modules\"/Markdown.bblm/Contents/Resources:" & ¬
	"/Applications/TextWrangler.app/Contents/PlugIns/\"Language Modules\"/Markdown.bblm/Contents/Resources:" & ¬
	"/Library/Scripts:" & ¬
	"/Library/Scripts/bin:" & ¬
	homepath & "Library/Scripts:" & ¬
	homepath & "Library/Scripts/bin:" & ¬
	homepath & "Library/\"Application Support\"/BBEdit/\"Unix Support\"/\"Unix Filters\":" & ¬
	homepath & "Library/\"Application Support\"/TextMate/Scripts:" & ¬
	homepath & "Library/\"Application Support\"/TextWrangler/\"Unix Support\"/\"Unix Filters\";"
set markdownCheck to do shell script pathAdditions & "Markdown.pl -shortversion; exit 0"
if markdownCheck = "" then
	set useMarkdown to false
end if
set smartypantsCheck to do shell script pathAdditions & "SmartyPants.pl -shortversion; exit 0"
if smartypantsCheck = "" then
	set useSmartyPants to false
end if

tell application "Journler.app"
	set blogEntries to «class psEN»
	if blogEntries = {} then
		display alert "There are no entries selected." message "Please select an entry to post." as warning buttons {"Cancel"} default button 1 giving up after 5
	else
		repeat with theEntry in blogEntries
			-- add tags for bold, italic, and/or non-black text			
			set entryFonts to {}
			set entryColors to {}
			repeat with textRun in every «class catr» of theEntry
				set entryFonts to entryFonts & {(font of textRun) as string}
				set entryColors to entryColors & {(color of textRun)}
			end repeat
			set entryText to every «class catr» of theEntry
			repeat with i from 1 to the number of items in entryText
				if item i of entryFonts contains "Bold" then
					set item i of entryText to "<strong>" & item i of entryText & "</strong>"
				end if
				if item i of entryFonts contains "Italic" then
					set item i of entryText to "<em>" & item i of entryText & "</em>"
				end if
				if item i of entryFonts contains "Oblique" then
					set item i of entryText to "<em>" & item i of entryText & "</em>"
				end if
				if item i of entryColors as string is not "000" then
					set item i of entryText to "<span style=\"color:" & my RGB_to_HEX(item i of entryColors) & ¬
						"\">" & item i of entryText & "</span>"
				end if
			end repeat
			set entryText to entryText as string
			-- apply Markdown
			if useMarkdown then
				set entryText to do shell script pathAdditions & ¬
					"echo " & quoted form of entryText & " | Markdown.pl;"
			end if
			-- apply SmartyPants
			if useSmartyPants then
				-- straighten any existing smart quotes so SmartyPants will recognize them
				repeat with smartyChar in smartyChars
					set entryText to my find_replace(item 1 of smartyChar, item 2 of smartyChar, entryText)
				end repeat
				set entryText to do shell script pathAdditions & ¬
					"echo " & quoted form of entryText & " | SmartyPants.pl -2;"
			end if
			-- convert special characters
			repeat with specialChar in specialChars
				if useNamedEntities then
					set entryText to my find_replace(item 1 of specialChar, item 2 of specialChar, entryText)
				else
					set entryText to my find_replace(item 1 of specialChar, item 3 of specialChar, entryText)
				end if
			end repeat
			-- display preview dialog before copying to clipboard and opening browser window
			if the button returned of (display dialog entryText with title (name of theEntry as string) ¬
				buttons {"Cancel", "Copy & Post"} cancel button 1 default button 2) is "Copy & Post" then
				set the clipboard to (do shell script "echo " & quoted form of entryText)
				if setEntryDate then
					set «class pDCD» of theEntry to (current date)
				end if
				set isTagged to false
				set theEntryTags to «class pTAG» of theEntry
				repeat with tag in theEntryTags
					if tag as string is equal to tagAsBlogged then
						set isTagged to true
					end if
				end repeat
				if isTagged is false then
					set «class pTAG» of theEntry to («class pTAG» of theEntry) & tagAsBlogged
				end if
				set entryNameEncoded to my encode_URL_string(name of theEntry)
				tell application "System Events"
					open location "http://www.blogger.com/blog_this.pyra?&n=" & entryNameEncoded
				end tell
			end if
		end repeat
		«event aevtcSVC»
	end if
end tell

property hex_list : (characters of "0123456789ABCDEF")
property allowed_URL_chars : (characters of "$-_.+!*(),1234567890abcdefghijklmnopqrstuvwxyz")
property smartyChars : {¬
	{"“", "\""}, ¬
	{"”", "\""}, ¬
	{"‘", "'"}, ¬
	{"’", "'"}, ¬
	{"–", "--"}, ¬
	{"—", "---"}, ¬
	{"…", "..."}}
-- since AppleScript supports only the MacRoman character set, only HTML entities within that set are listed
-- entity list from https://evolt.org/entities
property specialChars : {¬
	{" ", "&nbsp;", "&#160;", "non-breaking space"}, ¬
	{"¡", "&iexcl;", "&#161;", "inverted exclamation mark"}, ¬
	{"¢", "&cent;", "&#162;", "cent sign"}, ¬
	{"£", "&pound;", "&#163;", "pound sign"}, ¬
	{"¥", "&yen;", "&#165;", "yen sign"}, ¬
	{"§", "&sect;", "&#167;", "section sign"}, ¬
	{"¨", "&uml;", "&#168;", "diaeresis"}, ¬
	{"©", "&copy;", "&#169;", "copyright sign"}, ¬
	{"ª", "&ordf;", "&#170;", "feminine ordinal indicator"}, ¬
	{"«", "&laquo;", "&#171;", "left-pointing double angle quotation mark"}, ¬
	{"¬", "&not;", "&#172;", "not sign"}, ¬
	{"®", "&reg;", "&#174;", "registered sign"}, ¬
	{"¯", "&macr;", "&#175;", "macron"}, ¬
	{"°", "&deg;", "&#176;", "degree sign"}, ¬
	{"±", "&plusmn;", "&#177;", "plus-minus sign"}, ¬
	{"´", "&acute;", "&#180;", "acute accent"}, ¬
	{"µ", "&micro;", "&#181;", "micro sign"}, ¬
	{"¶", "&para;", "&#182;", "pilcrow sign"}, ¬
	{"·", "&middot;", "&#183;", "middle dot"}, ¬
	{"¸", "&cedil;", "&#184;", "cedilla"}, ¬
	{"º", "&ordm;", "&#186;", "masculine ordinal indicator"}, ¬
	{"»", "&raquo;", "&#187;", "right-pointing double angle quotation mark"}, ¬
	{"1⁄4", "&frac14;", "&#188;", "vulgar fraction one quarter"}, ¬
	{"1⁄2", "&frac12;", "&#189;", "vulgar fraction one half"}, ¬
	{"3⁄4", "&frac34;", "&#190;", "vulgar fraction three quarters"}, ¬
	{"¿", "&iquest;", "&#191;", "inverted question mark"}, ¬
	{"À", "&Agrave;", "&#192;", "latin capital letter A with grave"}, ¬
	{"Á", "&Aacute;", "&#193;", "latin capital letter A with acute"}, ¬
	{"Â", "&Acirc;", "&#194;", "latin capital letter A with circumflex"}, ¬
	{"Ã", "&Atilde;", "&#195;", "latin capital letter A with tilde"}, ¬
	{"Ä", "&Auml;", "&#196;", "latin capital letter A with diaeresis"}, ¬
	{"Å", "&Aring;", "&#197;", "latin capital letter A with ring above"}, ¬
	{"Æ", "&AElig;", "&#198;", "latin capital letter AE"}, ¬
	{"Ç", "&Ccedil;", "&#199;", "latin capital letter C with cedilla"}, ¬
	{"È", "&Egrave;", "&#200;", "latin capital letter E with grave"}, ¬
	{"É", "&Eacute;", "&#201;", "latin capital letter E with acute"}, ¬
	{"Ê", "&Ecirc;", "&#202;", "latin capital letter E with circumflex"}, ¬
	{"Ë", "&Euml;", "&#203;", "latin capital letter E with diaeresis"}, ¬
	{"Ì", "&Igrave;", "&#204;", "latin capital letter I with grave"}, ¬
	{"Í", "&Iacute;", "&#205;", "latin capital letter I with acute"}, ¬
	{"Î", "&Icirc;", "&#206;", "latin capital letter I with circumflex"}, ¬
	{"Ï", "&Iuml;", "&#207;", "latin capital letter I with diaeresis"}, ¬
	{"Ñ", "&Ntilde;", "&#209;", "latin capital letter N with tilde"}, ¬
	{"Ò", "&Ograve;", "&#210;", "latin capital letter O with grave"}, ¬
	{"Ó", "&Oacute;", "&#211;", "latin capital letter O with acute"}, ¬
	{"Ô", "&Ocirc;", "&#212;", "latin capital letter O with circumflex"}, ¬
	{"Õ", "&Otilde;", "&#213;", "latin capital letter O with tilde"}, ¬
	{"Ö", "&Ouml;", "&#214;", "latin capital letter O with diaeresis"}, ¬
	{"Ø", "&Oslash;", "&#216;", "latin capital letter O with stroke"}, ¬
	{"Ù", "&Ugrave;", "&#217;", "latin capital letter U with grave"}, ¬
	{"Ú", "&Uacute;", "&#218;", "latin capital letter U with acute"}, ¬
	{"Û", "&Ucirc;", "&#219;", "latin capital letter U with circumflex"}, ¬
	{"Ü", "&Uuml;", "&#220;", "latin capital letter U with diaeresis"}, ¬
	{"ß", "&szlig;", "&#223;", "latin small letter sharp s"}, ¬
	{"à", "&agrave;", "&#224;", "latin small letter a with grave"}, ¬
	{"á", "&aacute;", "&#225;", "latin small letter a with acute"}, ¬
	{"â", "&acirc;", "&#226;", "latin small letter a with circumflex"}, ¬
	{"ã", "&atilde;", "&#227;", "latin small letter a with tilde"}, ¬
	{"ä", "&auml;", "&#228;", "latin small letter a with diaeresis"}, ¬
	{"å", "&aring;", "&#229;", "latin small letter a with ring above"}, ¬
	{"æ", "&aelig;", "&#230;", "latin small letter ae"}, ¬
	{"ç", "&ccedil;", "&#231;", "latin small letter c with cedilla"}, ¬
	{"è", "&egrave;", "&#232;", "latin small letter e with grave"}, ¬
	{"é", "&eacute;", "&#233;", "latin small letter e with acute"}, ¬
	{"ê", "&ecirc;", "&#234;", "latin small letter e with circumflex"}, ¬
	{"ë", "&euml;", "&#235;", "latin small letter e with diaeresis"}, ¬
	{"ì", "&igrave;", "&#236;", "latin small letter i with grave"}, ¬
	{"í", "&iacute;", "&#237;", "latin small letter i with acute"}, ¬
	{"î", "&icirc;", "&#238;", "latin small letter i with circumflex"}, ¬
	{"ï", "&iuml;", "&#239;", "latin small letter i with diaeresis"}, ¬
	{"ñ", "&ntilde;", "&#241;", "latin small letter n with tilde"}, ¬
	{"ò", "&ograve;", "&#242;", "latin small letter o with grave"}, ¬
	{"ó", "&oacute;", "&#243;", "latin small letter o with acute"}, ¬
	{"ô", "&ocirc;", "&#244;", "latin small letter o with circumflex"}, ¬
	{"õ", "&otilde;", "&#245;", "latin small letter o with tilde"}, ¬
	{"ö", "&ouml;", "&#246;", "latin small letter o with diaeresis"}, ¬
	{"÷", "&divide;", "&#247;", "division sign"}, ¬
	{"ø", "&oslash;", "&#248;", "latin small letter o with stroke"}, ¬
	{"ù", "&ugrave;", "&#249;", "latin small letter u with grave"}, ¬
	{"ú", "&uacute;", "&#250;", "latin small letter u with acute"}, ¬
	{"û", "&ucirc;", "&#251;", "latin small letter u with circumflex"}, ¬
	{"ü", "&uuml;", "&#252;", "latin small letter u with diaeresis"}, ¬
	{"ÿ", "&yuml;", "&#255;", "latin small letter y with diaeresis"}, ¬
	{"ƒ", "&fnof;", "&#402;", "latin small f with hook"}, ¬
	{"Ω", "&Omega;", "&#937;", "greek capital letter omega"}, ¬
	{"π", "&pi;", "&#960;", "greek small letter pi"}, ¬
	{"•", "&bull;", "&#8226;", "bullet"}, ¬
	{"…", "&hellip;", "&#8230;", "horizontal ellipsis"}, ¬
	{"⁄", "&frasl;", "&#8260;", "fraction slash"}, ¬
	{"™", "&trade;", "&#8482;", "trade mark sign"}, ¬
	{"∂", "&part;", "&#8706;", "partial differential"}, ¬
	{"∏", "&prod;", "&#8719;", "n-ary product"}, ¬
	{"∑", "&sum;", "&#8721;", "n-ary sumation"}, ¬
	{"√", "&radic;", "&#8730;", "square root"}, ¬
	{"∞", "&infin;", "&#8734;", "infinity"}, ¬
	{"∫", "&int;", "&#8747;", "integral"}, ¬
	{"≈", "&asymp;", "&#8776;", "almost equal to"}, ¬
	{"≠", "&ne;", "&#8800;", "not equal to"}, ¬
	{"≤", "&le;", "&#8804;", "less-than or equal to"}, ¬
	{"≥", "&ge;", "&#8805;", "greater-than or equal to"}, ¬
	{"◊", "&loz;", "&#9674;", "lozenge"}, ¬
	{"Œ", "&OElig;", "&#338;", "latin capital ligature OE"}, ¬
	{"œ", "&oelig;", "&#339;", "latin small ligature oe"}, ¬
	{"Ÿ", "&Yuml;", "&#376;", "latin capital letter Y with diaeresis"}, ¬
	{"ˆ", "&circ;", "&#710;", "modifier letter circumflex accent"}, ¬
	{"˜", "&tilde;", "&#732;", "small tilde"}, ¬
	{"–", "&ndash;", "&#8211;", "en dash"}, ¬
	{"—", "&mdash;", "&#8212;", "em dash"}, ¬
	{"‘", "&lsquo;", "&#8216;", "left single quotation mark"}, ¬
	{"’", "&rsquo;", "&#8217;", "right single quotation mark"}, ¬
	{"‚", "&sbquo;", "&#8218;", "single low-9 quotation mark"}, ¬
	{"“", "&ldquo;", "&#8220;", "left double quotation mark"}, ¬
	{"”", "&rdquo;", "&#8221;", "right double quotation mark"}, ¬
	{"„", "&bdquo;", "&#8222;", "double low-9 quotation mark"}, ¬
	{"†", "&dagger;", "&#8224;", "dagger"}, ¬
	{"‡", "&Dagger;", "&#8225;", "double dagger"}, ¬
	{"‰", "&permil;", "&#8240;", "per mille sign"}, ¬
	{"‹", "&lsaquo;", "&#8249;", "single left-pointing angle quotation mark"}, ¬
	{"›", "&rsaquo;", "&#8250;", "single right-pointing angle quotation mark"}, ¬
	{"€", "&euro;", "&#8364;", "euro sign"}, ¬
	{"∆", "&#8710;", "&#8710;", "increment"}, ¬
	{"ﬁ", "&#64257;", "&#64257;", "latin small ligature fi"}, ¬
	{"ﬂ", "&#64258;", "&#64258;", "latin small ligature fl"}, ¬
	{"", "&#63743;", "&#63743;", "Apple logo"}, ¬
	{"ı", "&#305;", "&#305;", "latin small letter dotless i"}, ¬
	{"˘", "&#728;", "&#728;", "breve"}, ¬
	{"˙", "&#729;", "&#729;", "dot above"}, ¬
	{"˚", "&#730;", "&#730;", "ring above"}, ¬
	{"˝", "&#733;", "&#733;", "double acute accent"}, ¬
	{"˛", "&#731;", "&#731;", "ogonek"}, ¬
	{"ˇ", "&#711;", "&#711;", "caron"}}

-- http://www.macosxautomation.com/applescript/sbrt/sbrt-04.html
on RGB_to_HEX(RGBvalues)
	set hex_value to ""
	repeat with RGBvalue in RGBvalues
		set this_value to RGBvalue div 256
		if this_value is 256 then set this_value to 255
		set x to item ((this_value div 16) + 1) of hex_list
		set y to item (((this_value / 16 mod 1) * 16) + 1) of hex_list
		set hex_value to (hex_value & x & y) as string
	end repeat
	return ("#" & hex_value)
end RGB_to_HEX

on find_replace(findText, replaceText, sourceText)
	set ASTID to AppleScript's text item delimiters
	set AppleScript's text item delimiters to findText
	set sourceText to text items of sourceText
	set AppleScript's text item delimiters to replaceText
	set sourceText to "" & sourceText
	set AppleScript's text item delimiters to ASTID
	return sourceText
end find_replace

-- http://schinckel.net/2006/03/04/searching-zen/
on encode_URL_string(this_item)
	set character_list to (characters of this_item)
	repeat with this_char in character_list
		if this_char is not in allowed_URL_chars then set this_char to my encode_URL_char(this_char)
	end repeat
	return character_list as string
end encode_URL_string

on encode_URL_char(this_char)
	set ASCII_num to (ASCII number this_char)
	set x to item ((ASCII_num div 16) + 1) of hex_list
	set y to item ((ASCII_num mod 16) + 1) of hex_list
	return ("%" & x & y) as string
end encode_URL_char
