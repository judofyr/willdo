syn match Willview_Cmd "^>" nextgroup=Willview_Query
syn match Willview_Query ".*\n" contained

hi def link Willview_Cmd Boolean
hi def link Willview_Query Identifier

