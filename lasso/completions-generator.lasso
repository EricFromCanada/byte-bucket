#!/usr/bin/lasso9
// [

/*
	CodaCompletion.plist Generator

	Writes a Lasso completions file for Coda 2 containing keywords listed in
	sys_listTypes and their member methods.
*/

fail_if(!$argv->second, -1, "A list of mode keywords is required")

output(" ")	// causes additional methods to be loaded

// Load and register contents of $LASSO9_MASTER_HOME/LassoModules/
database_initialize

// Load all of the libraries from builtins and lassoserver
// This forces all possible available types and methods to be registered
local(srcs =
	(:
		dir(sys_masterHomePath + 'LassoLibraries/builtins/')->eachFilePath,
		dir(sys_masterHomePath + 'LassoLibraries/lassoserver/')->eachFilePath
	)
)

with topLevelDir in delve(#srcs)
where not #topLevelDir->lastComponent->beginsWith('.')
do protect => {
	handle_error => {
		stdoutnl('Unable to load: ' + #topLevelDir + ' ' + error_msg)
	}
	library_thread_loader->loadLibrary(#topLevelDir)
	stdoutnl('Loaded: ' + #topLevelDir)
}

email_initialize
log_initialize
session_initialize

/**!
	completions type
	Given a list of keywords, generates and prints a list of completions as XML
*/
define completions => type {

	data private memberAttributes = map
	// map( tag('mm.insert') = pair(tag('insert'), true) , ... )	// for now
	// map( tag('mm.insert') = pair(tag('insert'), list( 'p0::tag', '-p1=?', '...these' )) , ... )
	data private completionWords = map
	// map( pair(tag('void'), set()) , pair(tag('array'), set(tag('mm.insert'), tag('mm.remove'), ... )) , ... )

	// require a line break-delimited string of keywords upon initialization
	public onCreate(input::string) => {
		with line in #input->eachLine
		where #line->size > 2
		let keyword = tag(#line)
		do {
			if(sys_listTypes->contains(#keyword)) => {
				local(memberIds = set)
				with member in #keyword->getType->listMethods
				where #member->typeName != ::null
				where #member->typeName != ::any
				let m_name = #member->methodName->asString
				where #m_name != 'oncreate'
				where #m_name->isAlpha(1)		// skip operators, 'x'(), _x()
				where not #m_name->beginsWith('private_')
				where not #m_name->endsWith('=')	// skip x=()
				do #memberIds->insert(.addMemberId(#member))
				.completionWords->insert(pair(#keyword, #memberIds))
			else
				.completionWords->insert(pair(#keyword, set))
			}
		}
	}

	// add a new member name to the map, given a signature and returning the member ID
	public addMemberId(member::signature)::tag => {
		local(memberId = 'mm.'+#member->methodName)
//		local(memberParams = list)
/*	// BUG: fails when processing the full list of keywords
		with paramsarray in #member->paramDescs
		where #member->paramDescs->size
		let name = #paramsarray->first
		let type = #paramsarray->second
		do {
			#memberId->append('.'+#name)
			if(#type != ::any) => #memberId->append(#type)		// BUG: will not allow `append('-'+#type)`
			#memberParams->insert(
				tag(
					(#paramsarray->get(3)->bitTest(2) ? '-' | '') +
					#paramsarray->first +
					(#paramsarray->second != ::any ? '::'+#paramsarray->second | '') +
					(#paramsarray->get(3)->bitTest(1) ? '=?' | '')
				)
			)
		}
		if(#member->restName != void) => {
			#memberParams->insert(tag('...' + (#member->restName != ::rest ? #member->restName)));
			#memberId->append('.'+#member->restName)
		}
*/
		// compromise: just keep track of a boolean indicating if params are possible
		local(memberParams = boolean(#member->paramDescs->size || #member->restName != void))
		.memberAttributes->insert(
			pair(
				tag(#memberId),						// new key for memberAttributes as tag
				pair(											// new value for memberAttributes
					#member->methodName,
					// ensure an entry for a method without parameters doesn't overwrite an earlier entry that does
					(.memberAttributes->contains(tag(#memberId)) && .memberAttributes->get(tag(#memberId))->second ? true | #memberParams)
				)
			)
		)
		return tag(#memberId)
	}

	// print XML for an item in memberAttributes
	public printMemberId(memberId::tag) => {
		local(memberIdBlock = '
		<key>'+#memberId+'</key>
		<dict>
			<key>String</key>
			<string>'+.memberAttributes->get(#memberId)->first+'</string>')
/*
		.memberAttributes->get(#memberId)->second->size ? #memberIdBlock->append('
			<key>Parameters</key>
			<array>' + (
				with param in .memberAttributes->get(#memberId)->second
				select '
				<string>'+#param+'</string>'
			)->asStaticArray->join + '
			</array>')
*/
		// add parens if parameters are possible for this method
		return #memberIdBlock + (
			.memberAttributes->get(#memberId)->second ? '
			<key>PostString</key>
			<string>()</string>
			<key>MoveCursor</key>
			<string>1</string>'
			) + '
		</dict>'
	}

	// print XML for Attributes block
	public printMemberIds => {
		return '
	<key>Attributes</key>
	<dict>' + (
				with memberId in .memberAttributes->keys		// ->keys is already alphabetized
				select .printMemberId(#memberId)
			)->asStaticArray->join + '
	</dict>'
	}

	// print XML for Completions block
	public printCompletionWords => {
		local(completionBlock = string)
		with keyword in .completionWords->keys		// ->keys is already alphabetized
		do {
			#completionBlock->append('
		<dict>
			<key>ID</key>
			<string>'+#keyword+'</string>
			<key>String</key>
			<string>'+#keyword+'</string>'
			)

			if(.completionWords->get(#keyword)->size) => {
				#completionBlock->append('
			<key>Children_ID</key>
			<array>')
				with memberId in .completionWords->get(#keyword)
				do #completionBlock->append('
				<string>'+#memberId+'</string>')
				#completionBlock->append('
			</array>')
			}

			#completionBlock->append('
		</dict>'
			)
		}
		return '
	<key>Completions</key>
	<array>'+#completionBlock+'
	</array>'
	}

	public asString => {
		return .printMemberIds + .printCompletionWords
	}

}

// start the timer
local(start) = millis

// write the file
local(f) = file("CodaCompletion.plist")

#f->doWithClose => {

#f->openTruncate
#f->writeString(`<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Comments</key>
	<dict>
		<key>EndTag</key>
		<string>*/</string>
		<key>SingleTag</key>
		<string>//</string>
		<key>StartTag</key>
		<string>/*</string>
	</dict>` + completions(file($argv->second)->readString) + `
	<key>Contexts</key>
	<array>
		<dict>
			<key>Regex</key>
			<string>\b(?&lt;top&gt;[a-z_][\w.]*)\s*(?:\((?&gt;[^()]*(?&gt;\([^()]*\)[^()]*)*)+\)\s*)?-&gt;\\?\s*(?&lt;attribute&gt;[a-z_][\w.]*)\z</string>
			<key>ShouldCompleteAll</key>
			<false/>
			<key>ShouldAppendCompletion</key>
			<false/>
			<key>ShouldCompleteInStringLiteral</key>
			<false/>
		</dict>
		<dict>
			<key>Regex</key>
			<string>\b(?&lt;top&gt;[a-z_][\w.]*)\s*(?:\((?&gt;[^()]*(?&gt;\([^()]*\)[^()]*)*)+\)\s*)?-&gt;\\?(?&lt;attribute&gt;)\z</string>
			<key>ShouldCompleteAll</key>
			<true/>
			<key>ShouldAppendCompletion</key>
			<false/>
			<key>ShouldCompleteInStringLiteral</key>
			<false/>
		</dict>
		<dict>
			<key>Regex</key>
			<string>\b(?&lt;top&gt;[a-z_][\w.]*)\z</string>
			<key>ShouldCompleteAll</key>
			<false/>
			<key>ShouldAppendCompletion</key>
			<false/>
			<key>ShouldCompleteInStringLiteral</key>
			<false/>
		</dict>
	</array>
	<key>SymbolTableContext</key>
	<dict>
		<key>MatchContexts</key>
		<array>
		</array>
	</dict>
	<key>Name</key>
	<string>Lasso</string>
	<key>VariablePrefixes</key>
	<array>
		<string>#</string>
		<string>$</string>
	</array>
</dict>
</plist>
`)

}

// show the time taken
stdoutnl('The code took ' + (millis - #start) + ' milliseconds to process.')
