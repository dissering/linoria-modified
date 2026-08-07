-- Linoria Modified entrypoint.
-- The normal example now opens the redesigned dashboard UI instead of the
-- original upstream Linoria sample.

local repo = 'https://raw.githubusercontent.com/dissering/linoria-modified/main/'

loadstring(game:HttpGet(repo .. 'LinoriaModifiedExample.lua'))()
