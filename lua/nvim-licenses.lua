local api = vim.api
local buf, win

local url = 'https://api.github.com/licenses'
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

  local border_title = ' Licenses '
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

local function close_window()
  if not window_open then
    return
  end
  window_open = false

  api.nvim_win_close(win, true)
end

local function get_licenses()
  local result = io.popen('curl -s ' .. url)

  if result == nil then
    return
  end

  local data = result:read('*a')
  result:close()

  return data
end

local function update_window()
  api.nvim_buf_set_option(buf, 'modifiable', true)

  local list = get_licenses()

  if list == nil then
    print('Failed to fetch licenses')
    close_window()
    return
  end

  local licenses = {}
  for license in string.gmatch(list, '"spdx_id": "(.-)"') do
    if license ~= nil then
      table.insert(licenses, license)
    end
  end

  api.nvim_buf_set_lines(buf, 0, -1, false, licenses)
  api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function get_license(license)
  local result = io.popen('curl -s https://api.github.com/licenses/' .. license)

  if result == nil then
    return
  end

  local data = result:read('*a')
  result:close()

  return data
end

local function select_license()
  local current_line = api.nvim_get_current_line()
  local license_json = get_license(current_line)

  if license_json == nil then
    print('Failed to fetch license')
    close_window()
    return
  end

  -- local source = license_json:match('"body": "(.-)"')
  -- match "body": (.-) to end of line
  local source = license_json:match('"body":(.-)$')
  local license = string.gsub(source, '\\n', '\n')

  local file = io.open('LICENSE.md', 'w')

  if file == nil then
    print('Failed to write LICENSE.md')
    close_window()
    return
  end

  close_window()
  file:write(license)
  file:close()
  print(current_line .. ' license written to LICENSE.md')
end

local function move_cursor()
  local new_pos = math.max(4, api.nvim_win_get_cursor(win)[1] - 1)
  api.nvim_win_set_cursor(win, { new_pos, 0 })
end

local function set_mappings()
  local mappings = {
    ['<esc>'] = 'close_window()',
    ['<cr>']  = 'select_license()',
  }

  for k, v in pairs(mappings) do
    api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"nvim-licenses".' .. v .. '<cr>', {
      nowait = true, noremap = true, silent = true
    })
  end
end

local function licenses()
  open_window()
  update_window()
  set_mappings()
  api.nvim_win_set_cursor(win, { 1, 0 })
end

return {
  licenses = licenses,
  update_window = update_window,
  select_license = select_license,
  move_cursor = move_cursor,
  close_window = close_window,
}
