local anchor = require('facets.anchor')
local registry = require('facets.registry')
local trouble = require('facets.trouble')
local eslint = require('facets.eslint')
local tsc = require('facets.tsc')
local knip = require('facets.knip')
local kotlin = require('facets.kotlin')
local pw = require('facets.playwright')
local pw_cli = require('facets.playwright.cli')

local checks = 0
local function check(label, cond)
  if not cond then
    error('facets_spec failed: ' .. label)
  end
  checks = checks + 1
end

-- 1. Parsers produce valid trouble.Item lists
local eslint_items = eslint.parse_json_results({
  {
    filePath = '/tmp/a.ts',
    messages = {
      { line = 3, column = 5, endLine = 3, endColumn = 10, message = 'no-unused-vars', ruleId = 'no-unused-vars', severity = 2 },
    },
  },
}, '/tmp')
check('eslint parser count', #eslint_items == 1)
check('eslint parser code', eslint_items[1].code == 'no-unused-vars')

local tsc_items = tsc.parse_output('src/app.ts(12,4): error TS2322: Type string is not assignable to number.\n', '/repo')
check('tsc parser count', #tsc_items == 1)
check('tsc parser code', tsc_items[1].code == 'TS2322')
check('tsc parser pos', tsc_items[1].pos[1] == 12 and tsc_items[1].pos[2] == 3)

local knip_items = knip.parse_json({
  issues = {
    {
      file = 'src/unused.ts',
      exports = { { name = 'deadFn', line = 8, col = 14 } },
    },
  },
}, '/repo')
check('knip parser count', #knip_items == 1)
check('knip parser code', knip_items[1].code == 'exports')

-- 2. Trouble sources & modes factory
check('trouble sources registered', trouble.sources.facets_eslint ~= nil and trouble.sources.facets_tsc ~= nil and trouble.sources.facets_knip ~= nil)
check('trouble modes built', trouble.modes.facet_eslint ~= nil and trouble.modes.facet_tsc ~= nil and trouble.modes.facet_knip ~= nil)

-- 3. Playwright facet helpers + CLI parser (standalone, no nx.json)
check('is_pw_spec positive', pw.is_pw_spec('/repo/apps/web-e2e/src/login.spec.ts') == true)
check('is_pw_spec negative', pw.is_pw_spec('/repo/apps/web/src/login.spec.ts') == false)
check('pw_cli minor_version', pw_cli.minor_version('1.62.0') == '1.62')
local sample_help = [[
Options:
  --debug [mode]                   Run tests with Playwright Inspector
  -g, --grep <grep>                Only run tests matching
]]
local parsed_opts = pw_cli.parse_help(sample_help)
check('pw_cli parse_help count', #parsed_opts >= 2)

-- 4. Synthetic Node + TypeScript + Playwright repo detection
local tmp_node = vim.fn.tempname()
vim.fn.mkdir(tmp_node, 'p')
vim.fn.writefile({
  vim.fn.json_encode({
    name = 'sample-node',
    devDependencies = {
      eslint = '^9.0.0',
      knip = '^5.0.0',
      ['@playwright/test'] = '^1.50.0',
    },
  }),
}, tmp_node .. '/package.json')
vim.fn.writefile({ '{}' }, tmp_node .. '/tsconfig.json')
vim.fn.writefile({ 'export default {}' }, tmp_node .. '/playwright.config.ts')
vim.fn.writefile({ 'BASE_URL=https://default.invalid' }, tmp_node .. '/.env')
vim.fn.writefile({ 'BASE_URL=https://int.invalid' }, tmp_node .. '/.env.int')

local node_ctx = {
  root = tmp_node,
  stacks = anchor.stacks_at(tmp_node),
  stack_kinds = { node = true },
  cache_key = 'test-node',
}
registry.invalidate()
local active_node = registry.active(node_ctx)
local seen = {}
for _, entry in ipairs(active_node) do
  seen[entry.def.id] = true
end
check('detect typescript.eslint', seen['typescript.eslint'] == true)
check('detect typescript.tsc', seen['typescript.tsc'] == true)
check('detect typescript.knip', seen['typescript.knip'] == true)
check('detect playwright.e2e', seen['playwright.e2e'] == true)
check('trouble choices for node repo', #registry.trouble_choices(node_ctx) == 3)
check('pw find_pw_config_dir standalone', pw.find_pw_config_dir(tmp_node) == vim.fn.fnamemodify(tmp_node, ':p'):gsub('/$', ''))
check('pw dotenv fallback configs', vim.tbl_contains(pw.e2e_configurations(tmp_node), 'int'))
check('pw parse_dotenv', pw.parse_dotenv(tmp_node .. '/.env.int').BASE_URL == 'https://int.invalid')
vim.fn.delete(tmp_node, 'rf')

-- 5. Synthetic Gradle + Kotlin repo detection
local tmp_kt = vim.fn.tempname()
vim.fn.mkdir(tmp_kt .. '/src/main/kotlin', 'p')
vim.fn.writefile({ 'plugins { kotlin("jvm") }' }, tmp_kt .. '/build.gradle.kts')
local kt_ctx = {
  root = tmp_kt,
  stacks = anchor.stacks_at(tmp_kt),
  stack_kinds = { gradle = true },
  cache_key = 'test-kt',
}
local active_kt = registry.active(kt_ctx)
check('detect kotlin.jvm', #active_kt == 1 and active_kt[1].def.id == 'kotlin.jvm')
check('kotlin lsp spec', vim.tbl_contains(kotlin.lsp(kt_ctx).enable, 'kotlin_lsp'))
vim.fn.delete(tmp_kt, 'rf')

-- 6. Architectural boundary check: neotest, dap, and facets/playwright do not require('nx.*')
for _, rel in ipairs({
  'plugin/neotest.lua',
  'plugin/dap.lua',
  'lua/facets/playwright/init.lua',
  'lua/facets/playwright/cli.lua',
}) do
  local text = table.concat(vim.fn.readfile(vim.fn.getcwd() .. '/' .. rel), '\n')
  check('no nx.* require in ' .. rel, not text:find("require%(['\"]nx%."))
end

print(string.format('facets: %d checks passed', checks))
