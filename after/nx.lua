local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local M = {}

-- Helper: Read JSON file safely
local function read_project_json(filepath)
  local file = io.open(filepath, 'r')
  if not file then
    return nil
  end
  local content = file:read '*all'
  file:close()
  return vim.json.decode(content)
end

-- Main function to compose and run tests
function M.run_nx_test()
  local current_file = vim.fn.expand '%:p'
  -- Locate the nearest project.json going upwards from the current file
  local project_json_path = vim.fn.findfile('project.json', current_file .. ';')

  if project_json_path == '' then
    vim.notify('No project.json found relative to this file!', vim.log.levels.ERROR)
    return
  end

  local project_data = read_project_json(project_json_path)
  if not project_data or not project_data.targets or not project_data.targets.test then
    vim.notify("No 'test' target found in " .. project_json_path, vim.log.levels.WARN)
    return
  end

  local project_name = project_data.name
  local test_target = project_data.targets.test
  local options_list = {}

  -- 1. Gather all legal configuration names or options
  if test_target.configurations then
    for config_name, _ in pairs(test_target.configurations) do
      table.insert(options_list, { type = 'config', name = config_name })
    end
  end

  -- Add a default fallback option if no configurations are explicitly defined
  table.insert(options_list, 1, { type = 'default', name = 'Default (No Extra Flags)' })

  -- 2. Present legal configurations to the user via Telescope
  pickers
    .new({}, {
      prompt_title = 'Select Test Configuration for ' .. project_name,
      finder = finders.new_table {
        results = options_list,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name,
            ordinal = entry.name,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          -- 3. Ask the user if they want to attach a debug server
          vim.ui.select({ 'No', 'Yes (Node Inspector --inspect-brk)', 'Yes (Custom Flag)' }, {
            prompt = 'Attach to a Debug Server?',
          }, function(debug_choice)
            if not debug_choice then
              return
            end

            -- Base execution command
            local cmd = 'npx nx test ' .. project_name

            -- Append selected legal configuration if valid
            if selection.value.type == 'config' then
              cmd = cmd .. ' -c ' .. selection.value.name
            end

            -- Append debug hooks based on choice
            if debug_choice:find 'Node Inspector' then
              -- Prepend Node inspection to the execution context or pass inline via nodeOptions
              cmd = "NODE_OPTIONS='--inspect-brk' " .. cmd
            elseif debug_choice:find 'Custom' then
              -- Fallback option if your test runner framework uses standard CLI args like --debug
              cmd = cmd .. ' --debug'
            end

            -- 4. Execute the fully composed task in an interactive toggle terminal
            vim.cmd('split | terminal ' .. cmd)
            vim.cmd 'startinsert'
          end)
        end)
        return true
      end,
    })
    :find()
end

-- Keymap to trigger the composer
vim.keymap.set('n', '<leader>nt', M.run_nx_test, { desc = 'Compose Nx Test with Debug option' })

return M
