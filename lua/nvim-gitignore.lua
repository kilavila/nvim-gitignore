local api = vim.api
local buf, win

local url = 'https://api.github.com/gitignore/templates'
local window_open = false

local function open_window()
  if window_open then
    return
  end
  window_open = true

  buf = api.nvim_create_buf(false, true)
  local border_buf = api.nvim_create_buf(false, true)

  api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  api.nvim_buf_set_option(buf, 'filetype', 'bufferlist')

  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.5 - 4)
  local win_width = math.ceil(width * 0.4)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local border_opts = {
    style = 'minimal',
    relative = 'editor',
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1
  }

  local opts = {
    style = 'minimal',
    relative = 'editor',
    width = win_width,
    height = win_height,
    row = row,
    col = col
  }

  local border_title = ' github/gitignore '
  local border_lines = { '╭' .. border_title .. string.rep('─', win_width - string.len(border_title)) .. '╮' }
  local middle_line = '│' .. string.rep(' ', win_width) .. '│'
  for _ = 1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╰' .. string.rep('─', win_width) .. '╯')
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  local border_win = api.nvim_open_win(border_buf, true, border_opts)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)

  api.nvim_win_set_option(win, 'cursorline', true)
end

local function get_gitignore_templates()
  local handle = io.popen('curl -s ' .. url)

  if handle == nil then
    return {'Could not fetch gitignore templates'}
  end

  local output = handle:read('*a')
  handle:close()

  print(output)
  return vim.split(output, '\n')
end

local function update_window()
  api.nvim_buf_set_option(buf, 'modifiable', true)

  local templates_list = get_gitignore_templates()

  api.nvim_buf_set_lines(buf, 0, -1, false, templates_list)
  api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function close_window()
  if not window_open then
    return
  end
  window_open = false

  api.nvim_win_close(win, true)
end

local function move_cursor()
  local new_pos = math.max(4, api.nvim_win_get_cursor(win)[1] - 1)
  api.nvim_win_set_cursor(win, { new_pos, 0 })
end

local function set_mappings()
  local mappings = {
    ['<esc>'] = 'close_window()',
    ['<cr>']  = '',
    q         = 'close_window()',
    h         = '',
    l         = '',
  }

  for k, v in pairs(mappings) do
    api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"nvim-yoink".' .. v .. '<cr>', {
      nowait = true, noremap = true, silent = true
    })
  end

  local other_chars = {
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'i', 'm', 'n', 'o', 'p', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  }

  for _, v in ipairs(other_chars) do
    api.nvim_buf_set_keymap(buf, 'n', v, '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n', v:upper(), '', { nowait = true, noremap = true, silent = true })
    api.nvim_buf_set_keymap(buf, 'n', '<c-' .. v .. '>', '', { nowait = true, noremap = true, silent = true })
  end
end

local function gitignore()
  open_window()
  update_window()
  set_mappings()
  api.nvim_win_set_cursor(win, { 1, 0 })
end

return {
  gitignore = gitignore,
  update_window = update_window,
  move_cursor = move_cursor,
  close_window = close_window,
}