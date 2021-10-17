" Search for text, ignoring diacritics

function s:dsearch(query)
    let s:updated_query = ""
    for s:char in split(a:query, '\zs')
        if s:char == 'a'
            let s:updated_query .= "[aáâàāä]"
        elseif s:char == 'e'
            let s:updated_query .= "[eéêèēë]"
        elseif s:char == 'i'
            let s:updated_query .= "[iíîìīï]"
        elseif s:char == 'o'
            let s:updated_query .= "[oóôóōö]"
        elseif s:char == 'u'
            let s:updated_query .= "[uúûùūü]"
        else
            let s:updated_query .= s:char
        endif
    endfor
    execute "normal /" . s:updated_query . ""
    let @/ = s:updated_query
endfunction
command -nargs=1 Dsearch call s:dsearch(<f-args>)

" fôó
" foo
