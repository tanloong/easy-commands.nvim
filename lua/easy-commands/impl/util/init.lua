local M = {}

function M.ReplacePattern(str, pattern, replacement)
  return string.gsub(str, pattern, replacement)
end

function M.EndsWithSuffix(str, suffix)
  local len = #suffix
  return str:sub(-len) == suffix
end

M.getFiletype = function()
  return vim.bo.ft
end

---@param cmd string
---@return string|nil
function M.Call_sys_cmd(cmd)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

---@param content string
function M.CopyToSystemClipboard(content)
  local copy_cmd = 'pbcopy'
  -- Copy the absolute path to the clipboard
  if vim.fn.has('mac') or vim.fn.has('macunix') then
    copy_cmd = 'pbcopy'
  elseif vim.fn.has('win32') or vim.fn.has('win64') then
    copy_cmd = 'clip'
  elseif vim.fn.has('unix') then
    copy_cmd = 'xclip -selection clipboard'
  else
    print('Unsupported operating system')
    return
  end

  vim.fn.system(copy_cmd, content)
end

function M.Trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function M.ExitCurrentMode()
  local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'x', false)
end

-- https://gitlab.com/jrop/dotfiles/-/blob/master/.config/nvim/lua/my/utils.lua#L13
---@return string
function M.Buf_vtext()
  local a_orig = vim.fn.getreg('a')
  local mode = vim.fn.mode()
  if mode ~= 'v' and mode ~= 'V' then
    vim.cmd([[normal! gv]])
  end
  vim.cmd([[silent! normal! "aygv]])
  local text = vim.fn.getreg('a')
  vim.fn.setreg('a', a_orig)
  return text
end

local function replace_selected_text_with_clipboard()
  vim.cmd([[normal! gv"_dP]])
end

-- cmdFunc could do some trick to the selectedText
function M.Perform_cmd_to_selected_text(cmdFunc)
  local selectedText = M.Buf_vtext()
  local output = M.Call_sys_cmd(cmdFunc(selectedText))
  M.CopyToSystemClipboard(M.Trim(output))
  replace_selected_text_with_clipboard()
end

local function is_homedir(path)
  local home_dir = vim.loop.os_homedir()
  return path == home_dir
end

local function contains_marker_file(path)
  local marker_files = { ".git", ".gitignore" } -- list of marker files
  for _, file in ipairs(marker_files) do
    local full_path = path .. "/" .. file
    if vim.fn.filereadable(full_path) == 1 or vim.fn.isdirectory(full_path) == 1 then
      return true
    end
  end
  return false
end

---@return string|nil
function M.FindProjectPath()
  for i = 1, 30, 1 do
    local dir = vim.fn.expand("%:p" .. string.rep(":h", i))
    print(dir)
    if contains_marker_file(dir) then
      return dir
    end
    if is_homedir(dir) then
      return print("didn't found project_path")
    end
  end
  return print("excide the max depth")
end

return M
