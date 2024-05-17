local M = {}

local function replace_selection(new_text)
  local bufnr = vim.api.nvim_get_current_buf()

  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_line = end_pos[2] - 1
  local end_col = end_pos[3] - 1

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

  if #lines == 1 then
    lines[1] = lines[1]:sub(1, start_col) .. new_text .. lines[1]:sub(end_col + 2)
  end

  vim.api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, lines)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), 'n', true)
end

local function get_visual_selection()
  -- this will exit visual mode
  -- use 'gv' to reselect the text
  local _, csrow, cscol, cerow, cecol
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "␖" then
    -- if we are in visual mode use the live position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("."))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
    if mode == "V" then
      -- visual line doesn't provide columns
      cscol, cecol = 0, 999
    end
    -- exit visual mode
    -- vim.api.nvim_feedkeys(
    --   vim.api.nvim_replace_termcodes("<Esc>",
    --     true, false, true), "n", true)
  else
    -- otherwise, use the last known visual position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
  end
  -- swap vars if needed
  if cerow < csrow then csrow, cerow = cerow, csrow end
  if cecol < cscol then cscol, cecol = cecol, cscol end
  local lines = vim.fn.getline(csrow, cerow)
  -- local n = cerow-csrow+1
  local n = M.tbl_length(lines)
  if n <= 0 then return "" end
  lines[n] = string.sub(lines[n], 1, cecol)
  lines[1] = string.sub(lines[1], cscol)
  return table.concat(lines, "\n")
end

function M.tbl_length(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local function replace_class_names(class_names, prefix)
  local result = {}
  for i in string.gmatch(class_names, "%S+") do
    local tailwind_class = string.gmatch(i, "([^:]+)$")()
    local tailwind_value = string.gmatch(tailwind_class, "([^%-]+)$")()
    local tailwind_class_prefix = string.sub(i, 1, string.len(i) - string.len(tailwind_class))

    if tonumber(tailwind_value, 10) ~= nil or tailwind_value:match("^%[") then
      tailwind_class = string.gsub(tailwind_class, tailwind_value, "")
      tailwind_class = string.gsub(tailwind_class, "%[%]", "")
    else
      tailwind_value = ""
    end

    table.insert(result, tailwind_class_prefix .. prefix .. tailwind_class .. tailwind_value)
  end

  return table.concat(result, " ")
end


M.setup = function(opts)
end

M.replace = function(prefix)
  selection = get_visual_selection()
  result = replace_class_names(selection, prefix)
  replace_selection(result)
  return result
end

return M
