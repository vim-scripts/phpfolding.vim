" Plugin for automatic folding of PHP functions (also folds related PhpDoc)
"
" Maintainer: Ray Burgemeestre
" Last Change: 2006 Jul 31
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
	let s:foldsCreated = 0
	call s:PHPCustomFolds()

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
	" NOTE: Be sure to fold the smaller folds first, i.e. first functions then
	" classes. In reverse order the smaller folds won't be folded!

	" Fold function with PhpDoc (function foo() {})
	call s:PHPFoldPureBlock('function', s:FOLD_WITH_PHPDOC)
	
	" Fold class properties with PhpDoc (var $foo = NULL;)
	call s:PHPFoldProperties('^\s*var\s\$', ";", s:FOLD_WITH_PHPDOC)

	" Fold class without PhpDoc (class foo {})
	call s:PHPFoldPureBlock('class', s:FOLD_WITH_PHPDOC)
	
	" Fold marker style comments ({{{ foo }}})
	call s:PHPFoldMarkers('{{{', '}}}')
endfunction
" }}}
function! s:PHPFoldPureBlock(startPattern, ...) " {{{
	" Check function arguments
	if a:0 < 1
		" Default we also put the PHP doc part in the fold
		let s:currentPhpDocMode = s:FOLD_WITH_PHPDOC
	elseif a:0 == 1
		" Do we also put the PHP doc part in the fold?
		let s:currentPhpDocMode = a:1
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

	" Restore cursor
	exec s:savedCursor
endfunction
" }}}
function! s:PHPFoldProperties(startPattern, endPattern, ...) " {{{
	" Check function arguments
	if a:0 < 1
		" Default we also put the PHP doc part in the fold
		let s:currentPhpDocMode = s:FOLD_WITH_PHPDOC
	elseif a:0 == 1
		" Do we also put the PHP doc part in the fold?
		let s:currentPhpDocMode = a:1
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

			" Be greedy on an empty line postfixing the property declaration
			if getline(s:lineStop + 1) == ""
				let s:lineStop = s:lineStop + 1
			endif

			" Do something with the potential fold based on the Mode we're in
			call s:HandleFold(lineCurrent)
		else
			break
		endif
		let lineCurrent = lineCurrent + 1
	endwhile

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

	" Is there a closing C style */ on the above line?
	let checkLine = s:lineStart - 1
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
	if getline(line+1) == ""
		let line = line + 1
	endif
	return line
endfunction
" }}}
function! s:FindPatternEnd(endPattern) " {{{
	return search(a:endPattern, 'W')
endfunction
" }}}

function! PHPFoldText() " {{{
	let currentLine = v:foldstart
	let lines = (v:foldend - v:foldstart + 1)
	" See if we folded a marker
	if strridx(getline(currentLine), "{{{") != -1 " }}}
		let lineString = getline(currentLine)
		let lineString = substitute(lineString, '^.*{{{', '', 'g') " }}}
		break
	" See if we folded an API comment block
	elseif strridx(getline(currentLine), "\/\*\*") != -1
		" (I can't get search() or searchpair() to work.., therefore the
		" following loop)
		while currentLine < v:foldend
			if strridx(getline(currentLine), "\*\/") != -1
				let currentLine = currentLine + 1
				break
			endif
			let currentLine = currentLine + 1
		endwhile
		let lineString = getline(currentLine)
	else
		let lineString = getline(currentLine)
	endif
	
	"if currentLine != v:foldend 
		let lineString = substitute(lineString, '/\*\|\*/\d\=', '', 'g')
		let lineString = substitute(lineString, '^\s*', '', 'g')
		let lineString = substitute(lineString, '{$', '', 'g')
	"endif

	if lines < 10
		let lines = "  " . lines
	elseif lines < 100
		let lines = " " . lines
	endif
	if currentLine != v:foldstart
		let lineString = lineString . " [A]"
	endif	
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

" vim:ft=vim:foldmethod=marker:nowrap:tabstop=4:shiftwidth=4
