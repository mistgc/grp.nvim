local M = {}

function M._parse_grep_output(path)
    local filename, line = string.match(path, '([%w%-%._/]+%.%w+):(%d+):')
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

    -- Find right split window and non-terminal windows
    local right_split_win = nil
    local target_win = nil

    local wins = vim.api.nvim_tabpage_list_wins(0)
    for _, win in ipairs(wins) do
        local win_buf = vim.api.nvim_win_get_buf(win)
        local buftype = vim.api.nvim_buf_get_option(win_buf, 'buftype')

        -- Skip terminal windows
        if buftype ~= 'terminal' then
            -- Check if this is a right split by comparing positions
            local win_pos = vim.api.nvim_win_get_position(win)

            -- Simple heuristic: if window has a column > 0, it might be a right split
            if win_pos[2] > 0 then
                right_split_win = win
            else
                target_win = win
            end
        end
    end

    -- Use right split if exists, otherwise create new one
    local new_win
    if right_split_win then
        -- Load buffer in existing right split
        vim.api.nvim_win_set_buf(right_split_win, buf)
        new_win = right_split_win
    elseif target_win then
        -- Create new right split
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

    -- Wait for buffer to be fully loaded, then move cursor and add extmark
    vim.api.nvim_win_call(new_win, function()
        local line_num = tonumber(line)

        -- Jump to specific line
        vim.api.nvim_win_set_cursor(0, {line_num, 0})

        -- Add extmark for visual indication
        local ns_id = vim.api.nvim_create_namespace('grp_target')
        vim.api.nvim_buf_set_extmark(buf, ns_id, line_num - 1, 0, {
            hl_group = 'IncSearch',
            end_col = #vim.api.nvim_buf_get_lines(buf, line_num - 1, line_num, false)[1] or 0,
            priority = 1000
        })

        -- Clear extmark after a short delay
        vim.defer_fn(function()
            vim.api.nvim_buf_del_extmark(buf, ns_id, 1)
        end, 1000)

        -- Center the line
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
