" Vim plugin for adding folds to PHP functions and/or classes.
"
" This script is tested with the following Vim versions:
"   on windows gvim: 6.0, 6.3 and 7.0
"   on linux: 6.3
"
" INSTALL
"   1. Put phpfolding.vim in your plugins directory
"   2. It might be necessary that you load the plugin from your .vimrc, i.e.:
"        source ~/.vim/plugins/phpfolding.vim
"   3. You might want to add the following keyboard mappings too:
"        map <F6> <Esc>:EnablePHPFolds<Cr>
"        map <F7> <Esc>zE
"   4. Then in a PHP file you can press <F6> to automatically fold all PHP
"   functions and classes. <F7> will Remove all folds.
"
" MORE INFORMATION
"   In EnablePHPFolds() you can for example comment the PHPFold('class') call
"   to have the script not fold classes. You can also change the second
"   parameter passed to that function call, to have it or not have it fold PHP 
"   Doc API comments.
"
" Maintainer: Ray Burgemeestre
" Last Change: 2006 Jul 29

command! EnablePHPFolds call <SID>EnablePHPFolds()
command! -nargs=* PHPFold call <SID>PHPFold(<f-args>)

function! s:EnablePHPFolds() " {{{
	set foldmethod=manual
	set foldtext=PHPFoldText()

	let s:WITH_PHPDOC = 1
	let s:WITHOUT_PHPDOC = 0

	let s:foldsCreated = 0

	call s:PHPFold("function")
	call s:PHPFold("class", s:WITHOUT_PHPDOC)

	echo s:foldsCreated . " fold(s) created"
endfunction
" }}}
function! s:PHPFold(startPattern, ...) " {{{
	" Check function arguments
	if a:0 < 1
		" Default we also put the PHP doc part in the fold
		let s:currentPhpDocMode = s:WITH_PHPDOC
	elseif a:0 == 1
		" Do we also put the PHP doc part in the fold?
		let s:currentPhpDocMode = a:1
	endif

	" Store cursor
	if exists('*getpos')
		let savedCursor = getpos(".")
	endif
	" Move to file top
	0

	" Loop through file, searching for folds
	while 1
		let lineCurrent = s:FindFoldStart(a:startPattern)

		if lineCurrent != 0
			let s:lineStart = line('.')

			let s:lineStart = s:FindOptionalPHPDocComment()
			let s:lineStop = s:FindFoldEnd()

			" Stop on Error
			if s:lineStop == 0
				break
			endif

			" Fold
			exec s:lineStart . "," . s:lineStop . "fold"
			let s:foldsCreated = s:foldsCreated + 1
		else
			break
		endif
		let lineCurrent = lineCurrent + 1
	endwhile

	" Restore cursor
	if exists('savedCursor') && exists('*setpos')
		call setpos(".", savedCursor)
	endif
endfunction
" }}}
function! s:FindFoldStart(startPattern) " {{{
	" When the startPattern is 'function', this following search will match:
	"
	" function ...(...) {
	"
	" function ...(...)
	" {
	"
	" and even,
	"
	" function ...(...)
	" .. {
	return search(a:startPattern . '.*\%[\n].*{', 'W')
endfunction
" }}}
function! s:FindOptionalPHPDocComment() " {{{
	" Is searching for PHPDoc disabled?
	if s:currentPhpDocMode == s:WITHOUT_PHPDOC
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
function! s:FindFoldEnd() " {{{
	" Place Cursor on the opening brace
	let line = search('{', 'W')
	" Search for the entangled closing brace
	" call cursor(line, 1) " set the cursor to the start of the lnum line
	let line = searchpair('{', '{', '}', 'W', 'Skippmatch()')
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

function PHPFoldText() " {{{
	let currentLine = v:foldstart
	while currentLine <= v:foldend
		let lines = (v:foldend - v:foldstart + 1)
		if strridx(getline(currentLine), "function") != -1
			break
		elseif strridx(getline(currentLine), "class") != -1
			break
		endif
		let currentLine = currentLine + 1
	endwhile

	if (exists('*printf'))
		return "+--".printf("%3d", lines)." lines: " . getline(currentLine)
	else
		if lines < 10
			let lines = "  " . lines
		elseif lines < 100
			let lines = " " . lines
		endif
		return "+--".lines." lines: " . getline(currentLine)
	endif
endfunction
" }}}
function! Skippmatch() " {{{
" This function is copied from a PHP indent file by John Wellesz
" found here: http://www.2072productions.com/vim/indent/php.vim
" and here: http://www.vim.org/scripts/script.php?script_id=1120

	if (!exists('*synIDattr'))
		return 0
	endif

	let synname = synIDattr(synID(line("."), col("."), 0), "name")
	let userIsTypingComment = (exists('b:UserIsTypingComment') && b:UserIsTypingComment)
	if synname == "phpParent" || synname == "javaScriptBraces" || synname == "phpComment" && userIsTypingComment
		return 0
	else
		return 1
	endif
endfun
" }}}

" vim:ft=vim:foldmethod=marker:nowrap:tabstop=4:shiftwidth=4
