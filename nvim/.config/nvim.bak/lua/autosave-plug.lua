-- Enable autosave plugin
vim.g.auto_save = 1
-- by default this plugin autosaves when the text is changed
-- undo triggers a text changed event
-- and saving a file triggers an undo point to save
-- so if the save events include a text changed event, every undo creates a new
-- undo point so you can't go back anymore
vim.g.auto_save_events = { 'InsertLeave' }
-- TextYankPost seems to mess with the buffers
--let g:auto_save_events = [--InsertLeave--, --TextYankPost--] -- ['TextChanged']

-- Only save in Normal mode periodically. If the value is changed to '1',
-- then changes are saved when you are in Insert mode too, as you type, but
-- I would say prefer not save in Insert mode
vim.g.auto_save_in_insert_mode = 0
-- Silently autosave. If you disable this option by changing value to '0',
-- then in the vim status, it will display --(AutoSaved at <current time>)-- all
-- the time, which might get annoying
vim.g.auto_save_silent = 1
-- write all open buffers as if you would use :wa
--let g:auto_save_write_all_buffers = 1  --warning this makes it really slow

--And now turn Vim swapfile off
-- set noswapfile
