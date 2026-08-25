function! CustomizedSearch()
    let l:word = input('/')

    if l:word ==# ''
        return
    endif

    let l:found_lines = []

    for l:line_number in range(1, line('$'))
        let l:line_content = getline(l:line_number)

        if stridx(l:line_content, l:word) >= 0
            call add(l:found_lines, l:line_number)
        endif
    endfor

    if empty(l:found_lines)
        let l:message = [
                    \ ' Search Results ',
                    \ '',
                    \ '  "' . l:word . '"',
                    \ '',
                    \ '  Word not found',
                    \ ]
    else
        let l:message = [
                    \ ' Search Results ',
                    \ '',
                    \ '  "' . l:word . '"',
                    \ '',
                    \ '  Found in lines:',
                    \ ]

        for l:line_number in l:found_lines
            call add(l:message, '    Line ' . l:line_number)
        endfor
    endif

    call popup_create(l:message, {
                \ 'pos': 'right',
                \ 'minwidth': 25,
                \ 'maxwidth': 35,
                \ 'padding': [0, 1, 0, 1],
                \ 'border': [],
                \ 'close': 'button',
                \ })
endfunction

nnoremap / :call CustomizedSearch()<CR>