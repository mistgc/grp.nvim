local M = {}

function M._parse_grep_output(path)
    local filename, line = string.match(path, '([%.?%w.\\%/]+):(%d+):')
    return filename, line
end

function M._get_line_content()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1

    return vim.api.nvim_buf_get_lines(bufnr, row, row + 1, true)[1]
end

function M.open_file_at_line(filename, line)
    -- Create new buffer and load file
    local buf = vim.fn.bufadd(filename)
    vim.fn.bufload(buf)

    -- Find a suitable non-terminal window
    local target_win = nil
    local empty_win = nil

    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, win in ipairs(wins) do
        local win_buf = vim.api.nvim_win_get_buf(win)
        local buftype = vim.api.nvim_buf_get_option(win_buf, 'buftype')

        -- Skip terminal windows
        if buftype ~= 'terminal' then
            -- Check if buffer is empty (no lines or just whitespace)
            local lines = vim.api.nvim_buf_get_lines(win_buf, 0, -1, false)
            local is_empty = #lines == 0 or (#lines == 1 and lines[1] == '')

            if is_empty then
                empty_win = win
            else
                target_win = win
            end
        end
    end

    -- Use empty window if available, otherwise split a non-terminal window
    local new_win
    if empty_win then
        -- Load buffer in empty window
        vim.api.nvim_win_set_buf(empty_win, buf)
        new_win = empty_win
    elseif target_win then
        -- Split the non-terminal window
        new_win = vim.api.nvim_open_win(buf, true, {
            split = 'right',
            win = target_win,
            width = math.floor(vim.api.nvim_win_get_width(target_win) / 2)
        })
    else
        -- Create new window if no suitable window found
        new_win = vim.api.nvim_open_win(buf, true, {
            relative = 'editor',
            width = 80,
            height = 30,
            border = 'rounded'
        })
    end

    -- Jump to specific line
    vim.api.nvim_win_set_cursor(new_win, {tonumber(line), 0})

    -- Center the line
    vim.api.nvim_win_call(new_win, function()
        vim.fn.feedkeys('zz', 'n')
    end)
end

function M._enhanced_open_fn(path, opt)
    local content = M._get_line_content()
    local filename, line = M._parse_grep_output(content)
    if filename and line then
        M.open_file_at_line(filename, line)
    else
        M.original_open_fn(path, opt)
    end
end

function M.setup()
    M.original_open_fn = vim.ui.open
    vim.ui.open = M._enhanced_open_fn
end

return M
