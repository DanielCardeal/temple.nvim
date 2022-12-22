local M = {}

local TEMPLE_AUGROUP = vim.api.nvim_create_augroup('TempleAugroup', { clear = true })
local DEFAULT_CONFIG = {
    template_dir = vim.fn.stdpath 'config' .. '/templates'
}

---Write the contents of the `template` file to the current buffer.
---@param template string filepath of the template file to be used
local function write_template(template)
    vim.cmd('0r ' .. template)
end

---Callback function called when opening a new file.
---@param config table user configuration
---@param args table arguments received from the autocommand Nvim API
local function on_new_file(config, args)
    -- Get file extension of the new buffer
    local file_ext = vim.split(args.match, '.', true)
    if not file_ext[#file_ext] then
        return
    end
    file_ext = file_ext[#file_ext]
    -- Search templates with same file extension
    local regex = vim.regex("." .. file_ext .. "$")
    local template_files = vim.fs.find(
        function(fname) return regex:match_str(fname) ~= nil end,
        { path = config.template_dir, type = 'file', limit = math.huge }
    )
    if #template_files == 0 then
        return
    elseif #template_files == 1 then
        write_template(template_files[#template_files])
    else
        vim.ui.select(template_files, {}, write_template)
    end
end

---Setup global configuration options and initialize the plugin.
---@param config table
function M.setup(config)
    -- Parse input arguments
    config = config or {}
    if type(config) ~= 'table' then
        error('bad first parameter to `setup` function. Expected a table, got ' .. type(config) .. '.')
    end
    setmetatable(config, { __index = DEFAULT_CONFIG })
    -- Assert that `template_dir` is a valid path in the given operating system and that the path exists
    config.template_dir = vim.fs.normalize(config.template_dir)
    if vim.fn.isdirectory(config.template_dir) ~= 1 then
        print('Creating template dir at: ' .. config.template_dir)
        vim.fn.mkdir(config.template_dir)
    end
    -- Setup autocommand
    vim.api.nvim_create_autocmd({ 'BufNewFile' }, {
        pattern = "*",
        group = TEMPLE_AUGROUP,
        callback = function(args)
            on_new_file(config, args)
        end,
    })
end

return M
