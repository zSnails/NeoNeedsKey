---@class ActivationWindow
---@field buffer integer
---@field window_id integer
---@field namespace integer
local ActivationWindow = {}
ActivationWindow.__index = ActivationWindow

function ActivationWindow.new()
    local self = setmetatable({
        namespace = vim.api.nvim_create_namespace("neo-needs-key"),
        buffer_id = 0,
        window_id = 0,
    }, ActivationWindow)

    return self
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
        width = 36,
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
    -- TODO: make the window transparent.
    local buf_id = vim.api.nvim_create_buf(false, true)
    local config = create_window_config()
    local win_id = vim.api.nvim_open_win(buf_id, false, config)

    return buf_id, win_id
end

function ActivationWindow:close()
    vim.api.nvim_win_close(self.window_id, true)
end

function ActivationWindow:open()
    self.buffer, self.window_id = create_window()
    vim.api.nvim_buf_set_extmark(self.buffer, self.namespace, 0, 0, {
        virt_text = { { "Activate Neovim.", "Comment" } },
        virt_lines = {
            { { " Go to settings to activate neovim.", "Comment" } },
        },
    })
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

        vim.api.nvim_create_user_command("ActivateNeovim", function() window:close() end, {})
        vim.api.nvim_create_user_command("DeactivateNeovim", function() window:open() end, {})
        vim.defer_fn(function() window:open() end, opts.timeout * 1000)
    end
}
