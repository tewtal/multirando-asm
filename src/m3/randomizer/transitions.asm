;
; Support code for randomizing door transitions
; Needs to support connecting rooms in any way (and in that case re-orient movement vectors)
; Or is that too confusing? :D
;
; Also needs to support transitioning to other games
;
; Use standard SM door definitions, where door > $8000 = SM and < $8000 is other games (index lookup in tables)
; So for example $0001 = Zelda 1 -> Table index $01 and $1002 = Zelda 3 -> Table index $02
;





