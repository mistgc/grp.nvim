# grp.nvim

A Neovim plugin that enhances file opening functionality when working with grep output.

## Features

- Automatically detects grep-style file references (filename:line:) in the current line
- Opens files at the specified line number with smart window management
- Prioritizes empty windows before splitting existing ones
- Avoids opening files in terminal windows
- Centers the cursor on the target line

## Installation

Using your favorite plugin manager:

### Packer
```lua
use {
  'your-username/grp.nvim',
  config = function()
    require('grp').setup()
  end
}
```

### Vim-plug
```vim
Plug 'your-username/grp.nvim'
lua require('grp').setup()
```

### Lazy.nvim
```lua
{
  'your-username/grp.nvim',
  opts = {}
}
```

## Usage

After setup, the plugin automatically enhances `vim.ui.open` to detect grep-style patterns. When you're on a line containing a file reference like:

```
src/main.lua:42: some error message
```

The plugin will:
1. Parse the filename and line number
2. Open `src/main.lua` at line 42
3. Use smart window management to avoid disrupting your workflow

## Window Management Logic

1. **Empty windows**: Uses any existing empty (non-terminal) window
2. **Split windows**: Splits a suitable non-terminal window vertically (half width)
3. **Floating window**: Creates a floating window if no suitable window exists

## License

MIT
