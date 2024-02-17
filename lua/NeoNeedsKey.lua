---@class ActivationWindow
---@field buffer_id integer
---@field window_id integer
---@field namespace integer
---@field position string
local ActivationWindow = {}
ActivationWindow.__index = ActivationWindow

---@param opts table
function ActivationWindow.new(opts)
    local self = setmetatable({
        namespace = vim.api.nvim_create_namespace("neo-needs-key"),
        buffer_id = nil,
        window_id = nil,
        position = opts.position
    }, ActivationWindow)

    return self
end

function ActivationWindow:resize()
    if self.buffer_id ~= nil and self.window_id ~= nil then
        self:close()
        self:open()
    end
end

local positions = {
    ---@param width integer
    ---@return integer
    ---@return integer
    ["top-right"] = function(width, _)
        return math.max(width - 13, 0), 0
    end,
    ---@param width integer
    ---@param height integer
    ---@return integer
    ---@return integer
    ["bottom-right"] = function(width, height)
        return math.max(width - 13, 0), math.max(height - 2, 0)
    end,
    ---@return integer
    ---@return integer
    ["top-left"] = function(_, _)
        return 0, 0
    end,
    ---@param height integer
    ---@return integer
    ---@return integer
    ["bottom-left"] = function(_, height)
        return 0, math.max(height - 2, 0)
    end,
}


---@param position string
local function create_window_config(position)
    local ui = vim.api.nvim_list_uis()[1]
    local col, row = 0, 0
    if ui ~= nil then
        col, row = positions[position](ui.width, ui.height)
    end

    return {
        relative = "editor",
        anchor = "SW",
        col = col,
        row = row,
        width = 34,
        height = 2,
        border = "none",
        style = "minimal",
        noautocmd = true,
        focusable = false,
        zindex = 251
    }
end


---@param position string
---@return integer, integer
local function create_window(position)
    local buf_id = vim.api.nvim_create_buf(false, true)
    local config = create_window_config(position)
    local win_id = vim.api.nvim_open_win(buf_id, false, config)

    return buf_id, win_id
end

function ActivationWindow:close()
    if self.window_id ~= nil then
        vim.api.nvim_win_close(self.window_id, true)
    end

    if self.buffer_id ~= nil then
        vim.api.nvim_buf_delete(self.buffer_id, { force = true })
    end
    self.window_id = nil
    self.buffer_id = nil
end

function ActivationWindow:open()
    if self.window_id == nil and self.buffer_id == nil then
        self.buffer_id, self.window_id = create_window(self.position)

        vim.api.nvim_set_hl(self.namespace, "NormalFloat", { bg = "NONE" })
        vim.api.nvim_set_hl(self.namespace, "FloatBorder", { bg = "NONE" })
        vim.api.nvim_set_hl(self.namespace, "FloatTitle", { bg = "NONE" })
        vim.api.nvim_win_set_option(self.window_id, "winblend", 100)

        vim.api.nvim_win_set_hl_ns(self.window_id, self.namespace)
        vim.api.nvim_buf_set_extmark(self.buffer_id, self.namespace, 0, 0, {
            virt_text = { { "Activate Neovim.", "Comment" } },
            virt_text_pos = "overlay",
            virt_lines = {
                { { "Go to settings to activate neovim.", "Comment" } },
            },
        })
    end
end

---@param opts table
local function make_opts(opts)
    -- TODO: find a better way of doing options
    if opts == nil then
        opts = {
            timeout = 5,
            position = "bottom-right"
        }
    end

    if opts.timeout == nil then
        opts.timeout = 5
    end

    if opts.position == nil then
        opts.position = "bottom-right"
    end

    return opts
end

local setup_run = false

return {
    ActivationWindow = ActivationWindow,
    ---@param opts table
    setup = function(opts)
        if setup_run then
            return
        end
        opts = make_opts(opts)

        local window = ActivationWindow.new(opts)
        vim.api.nvim_create_autocmd("WinResized", {
            group = vim.api.nvim_create_augroup("NeoNeedsKey", { clear = true }),
            callback = function()
                window:resize()
            end,
        })
        vim.api.nvim_create_user_command("ActivateNeovim", function() window:close() end, {})
        vim.api.nvim_create_user_command("DeactivateNeovim", function() window:open() end, {})
        vim.defer_fn(function() window:open() end, opts.timeout * 1000)

        setup_run = true
    end
}
