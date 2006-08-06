" Plugin for automatic folding of PHP functions (also folds related PhpDoc)
"
" Maintainer: Ray Burgemeestre
" Last Change: 2006 Aug 7
"
" INSTALL
"   1. Put phpfolding.vim in your plugins directory
"   2. It might be necessary that you load the plugin from your .vimrc, 
"   i.e.:
"        source ~/.vim/plugins/phpfolding.vim
"   3! Make sure php_folding in disabled in your .vimrc, like:
"        let php_folding=0
"      Enabling this seems to interfere with this script.
"   4. You might want to add the following keyboard mappings too:
"        map <F5> <Esc>:EnableFastPHPFolds<Cr>
"        map <F6> <Esc>:EnablePHPFolds<Cr>
"        map <F7> <Esc>:DisablePHPFolds<Cr>
"   5. Then in a PHP file you can press <F5> to automatically fold all PHP
"   functions and classes. <F7> will Remove all folds. If in some PHP file
"   brackets mess up your folds, use <F6>. It does more extensive checking.
"
" MORE INFORMATION
"   In PHPCustomFolds() you can i.e. comment the PHPFoldPureBlock('class', ...) 
"   call to have the script not fold classes. You can also change the second
"   parameter passed to that function call, to have it or not have it fold
"   PhpDoc comments. All other folding you can turn on/off in this function.
"
"   You can tweak the foldtext to your liking in the function PHPFoldText().
"
"   This script is tested with Vim version >= 6.3 on windows and linux.

command! EnableFastPHPFolds call <SID>EnableFastPHPFolds()
command! -nargs=* EnablePHPFolds call <SID>EnablePHPFolds(<f-args>)
command! DisablePHPFolds call <SID>DisablePHPFolds()

" {{{ Script configuration
" Display the following after the foldtext if a fold contains phpdoc
let g:phpDocIncludedPostfix = '*'
" Default values
" .. search this # of empty lines for PhpDoc comments
let g:searchPhpDocLineCount = 1
" .. search this # of empty lines that 'trail' the foldmatch
let g:searchEmptyLinesPostfixing = 2
" }}}
" {{{ Script constants
let s:synIDattr_exists = exists('*synIDattr')
let s:TRUE = 1
let s:FALSE = 0
let s:MODE_CREATE_FOLDS = 1
let s:MODE_REMEMBER_FOLD_SETTINGS = 2
let s:FOLD_WITH_PHPDOC = 1
let s:FOLD_WITHOUT_PHPDOC = 0
" }}}

function! s:EnableFastPHPFolds() " {{{
	call s:EnablePHPFolds(s:FALSE)
endfunction
" }}}
function! s:EnablePHPFolds(...) " {{{
	" Check function arguments
	if a:0 == 0
		let s:extensiveBracketChecking = s:TRUE
	elseif a:0 == 1
		let s:extensiveBracketChecking = a:1
	endif
	
	" Initialize variables
	set foldmethod=manual
	set foldtext=PHPFoldText()
	let s:openFoldListItems = 0

	" First pass: Look for Folds, remember opened folds
	let s:foldingMode = s:MODE_REMEMBER_FOLD_SETTINGS
	call s:PHPCustomFolds()

	" Second pass: Recreate Folds, restore previously opened
	let s:foldingMode = s:MODE_CREATE_FOLDS
	" ..Remove all existing folds
	normal zE

	let s:searchPhpDocLineCount = g:searchPhpDocLineCount
	let s:searchEmptyLinesPostfixing = g:searchEmptyLinesPostfixing

	let s:foldsCreated = 0
	call s:PHPCustomFolds()

	" Fold all
	normal zM

	echo s:foldsCreated . " fold(s) created"
endfunction
" }}}
function! s:DisablePHPFolds() " {{{
	"set foldmethod=manual
	set foldtext=
	normal zE
	echo "php fold(s) deleted"
endfunction
" }}}
function! s:PHPCustomFolds() " {{{
	" NOTE: The 3rd and 4th parameter for functions PHPFoldProperties and
	" PHPFoldPureBlock overwrite respectively: g:searchPhpDocLineCount and
	" g:searchEmptyLinesPostfixing

	" Fold function with PhpDoc (function foo() {})
	call s:PHPFoldPureBlock('function', s:FOLD_WITH_PHPDOC)

	" Fold class properties with PhpDoc (var $foo = NULL;)
	call s:PHPFoldProperties('^\s*var\s\$', ";", s:FOLD_WITH_PHPDOC, 1, 0)

	" Fold class without PhpDoc (class foo {})
	call s:PHPFoldPureBlock('^\s*class', s:FOLD_WITH_PHPDOC)
	
	" Fold define()'s with their PhpDoc
	call s:PHPFoldProperties('^\s*define\s*(', ";", s:FOLD_WITH_PHPDOC, 1, 0)

	" Fold includes with their PhpDoc
	call s:PHPFoldProperties('^\s*require\s*', ";", s:FOLD_WITH_PHPDOC, 1, 0)
	call s:PHPFoldProperties('^\s*include\s*', ";", s:FOLD_WITH_PHPDOC, 1, 0)

	" Fold GLOBAL Arrays with their PhpDoc (some PEAR packages use these)
	call s:PHPFoldProperties('^\s*\$GLOBALS.*array\s*(', ";", s:FOLD_WITH_PHPDOC, 1, 0)

	" Fold marker style comments ({{{ foo }}})
	call s:PHPFoldMarkers('{{{', '}}}')
endfunction
" }}}
function! s:PHPFoldPureBlock(startPattern, ...) " {{{
	let s:searchPhpDocLineCount = g:searchPhpDocLineCount
	let s:searchEmptyLinesPostfixing = g:searchEmptyLinesPostfixing
	let s:currentPhpDocMode = s:FOLD_WITH_PHPDOC

	if a:0 >= 1
		" Do we also put the PHP doc part in the fold?
		let s:currentPhpDocMode = a:1
	endif
	if a:0 >= 2
		" How far do we want to look for PhpDoc comments?
		let s:searchPhpDocLineCount = a:2
	endif
	if a:0 == 3
		" How greedy are we on postfixing empty lines?
		let s:searchEmptyLinesPostfixing = a:3
	endif

	" Remember cursor information if possible
	let s:savedCursor = line(".")

	" Move to file top
	exec 0

	" Loop through file, searching for folds
	while 1
		let lineCurrent = s:FindPureBlockStart(a:startPattern)

		if lineCurrent != 0
			let s:lineStart = line('.')

			let s:lineStart = s:FindOptionalPHPDocComment()
			let s:lineStop = s:FindPureBlockEnd()

			" Stop on Error
			if s:lineStop == 0
				break
			endif

			" Do something with the potential fold based on the Mode we're in
			call s:HandleFold(lineCurrent)

		else
			break
		endif
		let lineCurrent = lineCurrent + 1
	endwhile

	" Remove created folds
	normal zR
	" Restore cursor
	exec s:savedCursor
endfunction
" }}}
function! s:PHPFoldMarkers(startPattern, endPattern) " {{{
	let s:currentPhpDocMode = s:FOLD_WITHOUT_PHPDOC
	" Remember cursor information if possible
	let s:savedCursor = line(".")

	" Move to file top
	exec 0

	" Loop through file, searching for folds
	while 1
		let lineCurrent = s:FindPatternStart(a:startPattern)

		if lineCurrent != 0
			let s:lineStart = line('.')

			let s:lineStart = s:FindOptionalPHPDocComment()
			let s:lineStop = s:FindPatternEnd(a:endPattern)

			" Stop on Error
			if s:lineStop == 0
				break
			endif

			" Do something with the potential fold based on the Mode we're in
			call s:HandleFold(lineCurrent)
		else
			break
		endif
		let lineCurrent = lineCurrent + 1
	endwhile

	" Remove created folds
	normal zR
	" Restore cursor
	exec s:savedCursor
endfunction
" }}}
function! s:PHPFoldProperties(startPattern, endPattern, ...) " {{{
	let s:searchPhpDocLineCount = g:searchPhpDocLineCount
	let s:searchEmptyLinesPostfixing = g:searchEmptyLinesPostfixing
	let s:currentPhpDocMode = s:FOLD_WITH_PHPDOC
	if a:0 >= 1
		" Do we also put the PHP doc part in the fold?
		let s:currentPhpDocMode = a:1
	endif
	if a:0 >= 2
		" How far do we want to look for PhpDoc comments?
		let s:searchPhpDocLineCount = a:2
	endif
	if a:0 == 3
		" How greedy are we on postfixing empty lines?
		let s:searchEmptyLinesPostfixing = a:3
	endif

	" Remember cursor information if possible
	let s:savedCursor = line(".")

	" Move to file top
	exec 0

	" Loop through file, searching for folds
	while 1
		let lineCurrent = s:FindPatternStart(a:startPattern)

		if lineCurrent != 0
			let s:lineStart = line('.')

			let s:lineStart = s:FindOptionalPHPDocComment()
			let s:lineStop = s:FindPatternEnd(a:endPattern)

			" Stop on Error
			if s:lineStop == 0
				break
			endif

			" Do something with the potential fold based on the Mode we're in
			call s:HandleFold(lineCurrent)
		else
			break
		endif
		let lineCurrent = lineCurrent + 1
	endwhile

	" Remove created folds
	normal zR
	" Restore cursor
	exec s:savedCursor
endfunction
" }}}
function! s:HandleFold(lineCurrent) " {{{
	let lineCurrent = a:lineCurrent

	if s:foldingMode == s:MODE_REMEMBER_FOLD_SETTINGS
		" If we are in an actual fold..
		if foldlevel(lineCurrent) != 0
			" .. and it is not closed
			if foldclosed(lineCurrent) == -1
				" Remember it as an open fold
				let s:foldsOpenedList{s:openFoldListItems} = getline(lineCurrent)
				let s:openFoldListItems = s:openFoldListItems + 1
			endif
		endif

	elseif s:foldingMode == s:MODE_CREATE_FOLDS
		" Create the actual fold!
		exec s:lineStart . "," . s:lineStop . "fold"

		" If the fold was previously open, it needs to be opened
		let currentItem = 0
		while currentItem < s:openFoldListItems
			" Was this line previously marked as an open fold?
			if s:foldsOpenedList{currentItem} == getline(lineCurrent)
				" Restore
				normal zo
			endif
			let currentItem = currentItem + 1
		endwhile

		" If the cursor is inside the fold, it needs to be opened
		if s:lineStart <= s:savedCursor && s:lineStop >= s:savedCursor
			normal zo
		endif

		let s:foldsCreated = s:foldsCreated + 1
	endif
endfunction
" }}}
function! s:FindPureBlockStart(startPattern) " {{{
	" When the startPattern is 'function', this following search will match:
	"
	" function foo($bar) {			function foo($bar)
	" {
	"
	" function foo($bar)			function foo($bar1,
	" .. {								$bar2)
	"								{
	"
	"return search(a:startPattern . '.*\%[\n].*{', 'W')
	return search(a:startPattern . '.*\%[\n].*\%[\n].*{', 'W')
endfunction
" }}}
function! s:FindPatternStart(startPattern) " {{{
	return search(a:startPattern, 'W')
endfunction
" }}}
function! s:FindOptionalPHPDocComment() " {{{
	" Is searching for PHPDoc disabled?
	if s:currentPhpDocMode == s:FOLD_WITHOUT_PHPDOC
		" .. Return the original Fold's start
		return s:lineStart
	endif

	" Skipover 'empty' lines in search for PhpDoc
	let s:counter = 0
	let s:currentLine = s:lineStart - 1
	while s:counter < s:searchPhpDocLineCount
		let line = getline(s:currentLine)
		if (matchstr(line, '^\s*$') == line)
			let s:currentLine = s:currentLine - 1
		endif
		let s:counter = s:counter + 1
	endwhile

	" Is there a closing C style */ on the above line?
	let checkLine = s:currentLine
	if strridx(getline(checkLine), "\*\/") != -1
		" Then search for the matching C style /* opener
		while 1
			if strridx(getline(checkLine), "\/\*") != -1
				" Only continue adjusting the Fold's start if it really is PHPDoc
				"  (which is characterized by a double asterisk, like /**)
				if strridx(getline(checkLine), "\/\*\*") != -1
					" .. Return this as the Fold's start
					return checkLine
				else
					break
				endif
			endif
			let checkLine = checkLine - 1
		endwhile
	endif
	" .. Return the original Fold's start
	return s:lineStart
endfunction
" }}}
function! s:FindPureBlockEnd() " {{{
	" Place Cursor on the opening brace
	let line = search('{', 'W')
	" Search for the entangled closing brace
	" call cursor(line, 1) " set the cursor to the start of the lnum line
	if s:extensiveBracketChecking == s:TRUE
		let line = searchpair('{', '{', '}', 'W', 'SkipMatch()')
	else
		let line = searchpair('{', '{', '}', 'W')
	endif
	if line == 0
		let line = search('}', 'W')
	endif
	if line == 0
		" Return error
		return 0
	endif

	" Be greedy with an extra 'trailing' empty line
	let s:counter = 0
	while s:counter < s:searchEmptyLinesPostfixing
		let linestr = getline(line + 1)		
		if (matchstr(linestr, '^\s*$') == linestr)
			let line = line + 1
		endif
		let s:counter = s:counter + 1
	endwhile

	return line
endfunction
" }}}
function! s:FindPatternEnd(endPattern) " {{{
	let line = search(a:endPattern, 'W')

	" Be greedy with an extra 'trailing' empty line
	let s:counter = 0
	while s:counter < s:searchEmptyLinesPostfixing
		let linestr = getline(line + 1)		
		if (matchstr(linestr, '^\s*$') == linestr)
			let line = line + 1
		endif
		let s:counter = s:counter + 1
	endwhile
	return line
endfunction
" }}}

function! PHPFoldText() " {{{
	let currentLine = v:foldstart
	let lines = (v:foldend - v:foldstart + 1)
	" See if we folded a marker
	if strridx(getline(currentLine), "{{{") != -1 " }}}
		let lineString = getline(currentLine)
		" Is there text after the fold opener?
		if (matchstr(lineString, '^.*{{{..*$') == lineString) " }}}
			" Then only show that text
			let lineString = substitute(lineString, '^.*{{{', '', 'g') " }}}
		" There is text before the fold opener
		else
			" Try to strip away the remainder
			let lineString = substitute(lineString, '\s*{{{.*$', '', 'g') " }}}
		endif
		break
	" See if we folded an API comment block
	elseif strridx(getline(currentLine), "\/\*\*") != -1
		" (I can't get search() or searchpair() to work.., therefore the
		" following loop)
		let s:state = 0
		while currentLine < v:foldend
			let line = getline(currentLine)
			if s:state == 0 && strridx(line, "\*\/") != -1
				" Found the end, now we need to find the first not-empty line
				let s:state = 1
			elseif s:state == 1 && (matchstr(line, '^\s*$') != line)
				" Found the line to display in fold!
				break
			endif
			let currentLine = currentLine + 1
		endwhile
		let lineString = getline(currentLine)
	else
		let lineString = getline(currentLine)
	endif
	
	" Some common replaces...
	" if currentLine != v:foldend 
		let lineString = substitute(lineString, '/\*\|\*/\d\=', '', 'g')
		let lineString = substitute(lineString, '^\s*', '', 'g')
		let lineString = substitute(lineString, '{$', '', 'g')
	" endif

	" Emulates printf("%3d", lines)..
	if lines < 10
		let lines = "  " . lines
	elseif lines < 100
		let lines = " " . lines
	endif

	" Append an (a) if there is PhpDoc in the fold (a for API)
	if currentLine != v:foldstart
		let lineString = lineString . " " . g:phpDocIncludedPostfix . " "
	endif	

	" Return the foldtext
	return "+--".lines." lines: " . lineString
endfunction
" }}}
function! SkipMatch() " {{{
" This function is modified from a PHP indent file by John Wellesz
" found here: http://www.vim.org/scripts/script.php?script_id=1120
	if (!s:synIDattr_exists)
		return 0
	endif
	let synname = synIDattr(synID(line("."), col("."), 0), "name")
	if synname == "phpParent" || synname == "javaScriptBraces" || synname == "phpComment"
		return 0
	else
		return 1
	endif
endfun
" }}}

" vim:ft=vim:foldmethod=marker:nowrap:tabstop=4:shiftwidth=44
