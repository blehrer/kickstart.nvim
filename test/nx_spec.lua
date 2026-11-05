local workspace = require('nx.workspace')
local pw_cli = require('nx.playwright_cli')

assert(workspace.normalize_remote('git@GitHub.com:Org/Repo.git') == 'git@github.com:Org/Repo')
assert(workspace.normalize_remote('https://GitHub.com/Org/Repo.git') == 'https://github.com/org/repo')

assert(pw_cli.minor_version('1.62.0') == '1.62')
local sample = [[
Options:
  --debug [mode]                   Run tests with Playwright Inspector
  -g, --grep <grep>                Only run tests matching
]]
local parsed = pw_cli.parse_help(sample)
assert(#parsed >= 2)
assert(parsed[1].flag == '--debug' or parsed[2].flag == '--debug')

print('nx: 4 checks passed')
