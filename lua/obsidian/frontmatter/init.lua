local M = {}
local yaml = require "obsidian.yaml"
local log = require "obsidian.log"
local validator = require "obsidian.frontmatter.validator"

local function sort_by_list(list)
  return function(a, b)
    local a_idx, b_idx = nil, nil
    for i, k in ipairs(list) do
      if a == k then
        a_idx = i
      end
      if b == k then
        b_idx = i
      end
    end
    if a_idx and b_idx then
      return a_idx < b_idx
    elseif a_idx then
      return true
    elseif b_idx then
      return false
    else
      return a < b
    end
  end
end

--- Get frontmatter lines to be written
---
---@param t table<string, any>
---@param order string[] | fun(a: any, b: any): boolean
---
---@return string[]
M.dump = function(t, order)
  local lines = { "---" }
  local order_f

  if order and type(order) == "table" and not vim.tbl_isempty(order) then
    order_f = sort_by_list(order)
  elseif order and type(order) == "function" then
    order_f = order
  end

  for _, line in ipairs(yaml.dumps_lines(t, order_f)) do
    table.insert(lines, line)
  end

  table.insert(lines, "---")

  return lines
end

TestFunc = function(arg1, arg2)


    local arg2 = arg2 or false
    print("arg1 is ", arg1, "arg2 is ", arg2)
end

--- Parse and validate info from frontmatter.
---
---@param frontmatter_lines string[]
---@return { id: string, tags: string[], aliases: string[] }
---@return table<string, any>
M.parse = function(frontmatter_lines, path)
  -- print("frontmatter lines = ")
  -- fml = vim.inspect(frontmatter_lines)
  -- print(fml)
  local frontmatter = table.concat(frontmatter_lines, "\n")
  print("calling yaml.loads from frontmatter/init.lua")
  -- pcall(TestFunc, "test1", true)
  local ok, data = pcall(yaml.loads, frontmatter, false)
  -- data_str = vim.inspect(data)
  -- print("yaml.loads: ", data_str)
  if type(data) ~= "table" then
    data = {}
  end
  if not ok then
    return {}, {}
  end
  local metadata, ret = {}, {}
  for k, v in pairs(data) do
    if validator[k] then
      local value, err = validator[k](v, path)
      if err ~= nil then
        log.warn(err)
      else
        ret[k] = value
      end
    else
      metadata[k] = v
    end
  end

  return ret, metadata
end

return M
