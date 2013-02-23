syn match Willdo_Item "^\* " nextgroup=Willdo_Ref
syn match Willdo_Ref "[^ ]\+" contained nextgroup=Willdo_Title
syn match Willdo_Title ".\+$" contained
syn match Willdo_Tag "^  :[^ ]\+"

hi def link Willdo_Item Keyword
hi def link Willdo_Ref Boolean
hi def link Willdo_Title Identifier
hi def link Willdo_Tag Comment

