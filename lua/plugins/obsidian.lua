---@module 'lazy.types'
---@type LazyPluginSpec[]
return {
  {
    'obsidian-nvim/obsidian.nvim',
    version = '*', -- recommended, use latest release instead of latest commit
    lazy = false,
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    --   'BufReadPre '
    --     .. vim.fn.expand '~'
    --     .. '/vaults/**',
    --   'BufNewFile ' .. vim.fn.expand '~' .. '/vaults/**',
    -- },
    dependencies = {
      -- Required.
      'nvim-lua/plenary.nvim',
      'sho-87/kanagawa-paper.nvim',

      -- see below for full list of optional dependencies 👇
    },
    opts = function()
      local palette = require('kanagawa-paper').load().palette
      ---@type obsidian.config.ClientOpts
      local custom_options = {
        legacy_commands = false,
        workspaces = {
          {
            name = 'noe',
            path = '~/vaults/noe',
          },
        },
        notes_subdir = 'notes',
        templates = {
          folder = 'templates',
          date_format = '%Y-%m-%d',
          time_format = '%H:%M',
          -- A map for custom variables, the key should be the variable and the value a function
          substitutions = {},
        },

        ui = {
          -- The options are passed directly to `vim.api.nvim_set_hl()`. See `:help nvim_set_hl`.
          hl_groups = palette and true and {
            ObsidianTodo = { bold = true, fg = palette.dragonGreen },
            ObsidianDone = { bold = true, fg = palette.dragonAqua },
            ObsidianRightArrow = { bold = true, fg = palette.dragonGreen },
            ObsidianTilde = { bold = true, fg = palette.dragonRed },
            ObsidianImportant = { bold = true, fg = palette.autumnRed },
            ObsidianBullet = { bold = true, fg = palette.dragonAqua },
            ObsidianRefText = { underline = true, fg = palette.dragonBlue },
            ObsidianExtLinkIcon = { fg = palette.dragonBlue },
            ObsidianTag = { italic = true, fg = palette.dragonAqua },
            ObsidianBlockID = { italic = true, fg = palette.dragonAqua },
            ObsidianHighlightText = { bg = palette.dragonBlue },
          },
          --   or {
          --   ObsidianTodo = { bold = true, fg = '#f78c6c' },
          --   ObsidianDone = { bold = true, fg = '#89ddff' },
          --   ObsidianRightArrow = { bold = true, fg = '#f78c6c' },
          --   ObsidianTilde = { bold = true, fg = '#ff5370' },
          --   ObsidianImportant = { bold = true, fg = '#d73128' },
          --   ObsidianBullet = { bold = true, fg = '#89ddff' },
          --   ObsidianRefText = { underline = true, fg = '#c792ea' },
          --   ObsidianExtLinkIcon = { fg = '#c792ea' },
          --   ObsidianTag = { italic = true, fg = '#89ddff' },
          --   ObsidianBlockID = { italic = true, fg = '#89ddff' },
          --   ObsidianHighlightText = { bg = '#75662e' },
          -- },
        },

        daily_notes = {
          -- Optional, if you keep daily notes in a separate directory.
          folder = 'notes/dailies',
          -- Optional, if you want to change the date format for the ID of daily notes.
          date_format = '%Y-%m-%d',
          -- Optional, if you want to change the date format of the default alias of daily notes.
          alias_format = '%B %-d, %Y',
          -- Optional, default tags to add to each new daily note created.
          default_tags = { 'daily-notes' },
          -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
          template = nil,
        },

        new_notes_location = 'notes_subdir',

        -- Optional, customize how note IDs are generated given an optional title.
        ---@param title string|?
        ---@return string
        note_id_func = function(title)
          -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
          -- In this case a note with the title 'My new note' will be given an ID that looks
          -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
          local suffix = ''
          if title ~= nil then
            -- If title is given, transform it into valid file name.
            suffix = title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
          else
            -- If title is nil, just add 4 random uppercase letters to the suffix.
            for _ = 1, 4 do
              suffix = suffix .. string.char(math.random(65, 90))
            end
          end
          return tostring(os.time()) .. '-' .. suffix
        end,

        -- Optional, alternatively you can customize the frontmatter data.
        ---@return table
        note_frontmatter_func = function(note)
          -- Add the title of the note as an alias.
          if note.title then
            note:add_alias(note.title)
          end

          local out = { id = note.id, aliases = note.aliases, tags = note.tags }

          -- `note.metadata` contains any manually added fields in the frontmatter.
          -- So here we just make sure those fields are kept in the frontmatter.
          if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
            for k, v in pairs(note.metadata) do
              out[k] = v
            end
          end

          return out
        end,

        -- Optional, by default when you use `:ObsidianFollowLink` on a link to an external
        -- URL it will be ignored but you can customize this behavior here.
        ---@param url string
        follow_url_func = function(url)
          -- Open the URL in the default web browser.
          vim.ui.open(url) -- need Neovim 0.10.0+
        end,

        -- Optional, by default when you use `:ObsidianFollowLink` on a link to an image
        -- file it will be ignored but you can customize this behavior here.
        ---@param img string
        follow_img_func = function(img)
          local uname = vim.system { 'uname' }
          if uname == 'Darwin' then
            vim.fn.jobstart { 'qlmanage', '-p', img } -- Mac OS quick look preview
          elseif uname == 'Linux' then
            vim.fn.jobstart { 'xdg-open', img } -- linux
          end
          -- vim.cmd(':silent exec "!start ' .. url .. '"') -- Windows
        end,

        picker = {
          -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', or 'mini.pick'.
          name = 'telescope.nvim',
          -- Optional, configure key mappings for the picker. These are the defaults.
          -- Not all pickers support all mappings.
          note_mappings = {
            -- Create a new note from your query.
            new = '<C-x>',
            -- Insert a link to the selected note.
            insert_link = '<C-l>',
          },
          tag_mappings = {
            -- Add tag(s) to current note.
            tag_note = '<C-x>',
            -- Insert a tag at the current location.
            insert_tag = '<C-l>',
          },
        },
        completion = {
          blink = true,
          nvim_cmp = false,
        },
      }
      return vim.tbl_deep_extend('force', require('obsidian.config').ClientOpts.default(), custom_options)
    end,
    keys = function()
      local O = function(subcommand)
        if subcommand then
          vim.cmd(('Obsidian %s'):format(subcommand))
        else
          vim.cmd 'Obsidian'
        end
      end
      return {
        {
          '<leader>snt',
          function()
            O 'tags'
          end,
          desc = '[S]earch: [n]otes by [t]ag',
        },
        {
          '<leader>sng',
          function()
            O 'search'
          end,
          desc = '[S]earch: [n]otes by [g]rep',
        },
        {
          '<leader>n',
          function()
            O()
          end,
        },
      }
    end,
  },
}
