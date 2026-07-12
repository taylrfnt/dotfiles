{ pkgs, ... }:
with pkgs.vimPlugins;
{
  # smart-splits: https://github.com/mrjones2014/smart-splits.nvim
  smart-splits = {
    setup = ''
      require('smart-splits').setup({
        resize_mode = {
          silent = true,
          hooks = {
            on_enter = function()
              vim.notify('Entering resize mode')
            end,
            on_leave = function()
              vim.notify('Exiting resize mode')
            end,
          },
        },
      })
    '';
    package = smart-splits-nvim;
  };

  # sidekick: https://github.com/folke/sidekick.nvim
  sidekick = {
    setup = ''
      require('sidekick').setup({
        cli = {
          tools = {
            amp = {
              cmd = { "amp", "--ide" },
            },
          },
        },
      })
    '';
    package = sidekick-nvim;
  };

  # amp: https://github.com/ampcode/amp.nvim
  amp = {
    setup = ''
      require('amp').setup({
        auto_start = true, log_level = info
      })
    '';
    package = amp-nvim;
  };

  # cloak - https://github.com/laytan/cloak.nvim
  cloak = {
    setup = ''
            require('cloak').setup({
              enabled = true,
              cloak_character = '*',
              -- The applied highlight group (colors) on the cloaking, see `:h highlight`.
              highlight_group = 'Comment',
              -- Applies the length of the replacement characters for all matched
              -- patterns, defaults to the length of the matched pattern.
              cloak_length = 6, -- Provide a number if you want to hide the true length of the value.
              -- Whether it should try every pattern to find the best fit or stop after the first.
              try_all_patterns = true,
              -- Set to true to cloak Telescope preview buffers. (Required feature not in 0.1.x)
              cloak_telescope = true,
              -- Re-enable cloak when a matched buffer leaves the window.
              cloak_on_leave = false,
              patterns = {
                {
                  -- Match any file starting with '.env'.
                  -- This can be a table to match multiple file patterns.
                  file_pattern = '.env*',
                  -- Match an equals sign and any character after it.
                  -- This can also be a table of patterns to cloak,
                  -- example: cloak_pattern = { ':.+', '-.+' } for yaml files.
                  cloak_pattern = '=.+',
                  -- A function, table or string to generate the replacement.
                  -- The actual replacement will contain the 'cloak_character'
                  -- where it doesn't cover the original text.
                  -- If left empty the legacy behavior of keeping the first character is retained.
                  replace = nil,
          },
        },
      })
    '';
    package = cloak-nvim;
  };
}
