---@class ActivationWindow
---@field buffer_id integer
---@field window_id integer
---@field namespace integer
local ActivationWindow = {}
ActivationWindow.__index = ActivationWindow

function ActivationWindow.new()
    local self = setmetatable({
        namespace = vim.api.nvim_create_namespace("neo-needs-key"),
        buffer_id = nil,
        window_id = nil,
    }, ActivationWindow)

    return self
end

function ActivationWindow:resize()
    if self.buffer_id ~= nil and self.window_id ~= nil then
        self:close()
        self:open()
    end
end

local function create_window_config()
    local ui = vim.api.nvim_list_uis()[1]
    local col = 12
    local row = 0
    if ui ~= nil then
        col = math.max(ui.width - 13, 0)
        row = math.max(ui.height - 2, 0)
    end

    return {
        relative = "editor",
        anchor = "SW",
        col = col,
        row = row,
        width = 35,
        height = 2,
        border = "none",
        style = "minimal",
        noautocmd = true,
        focusable = false,
        zindex = 251
    }
end

---@return integer, integer
local function create_window()
    local buf_id = vim.api.nvim_create_buf(false, true)
    local config = create_window_config()
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
        self.buffer_id, self.window_id = create_window()
        vim.api.nvim_set_hl(self.namespace, "NormalFloat", { bg = "NONE" })
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

return {
    ActivationWindow = ActivationWindow,
    ---@param opts table
    setup = function(opts)
        local window = ActivationWindow.new()
        if opts == nil then
            opts = {
                timeout = 10
            }
        end

        vim.api.nvim_create_autocmd("WinResized", {
            group = vim.api.nvim_create_augroup("NeoNeedsKey", { clear = true }),
            callback = function()
                window:resize()
            end,
        })
        vim.api.nvim_create_user_command("ActivateNeovim", function() window:close() end, {})
        vim.api.nvim_create_user_command("DeactivateNeovim", function() window:open() end, {})
        vim.defer_fn(function() window:open() end, opts.timeout * 1000)
    end
}
