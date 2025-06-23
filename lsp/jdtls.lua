require 'config.functions'

if HasMise() then
  local jdtls_rte_java = vim.fs.joinpath(MiseWhere('java', 21).path, 'bin', 'java')
  local jdtls_installation_dir = vim.fs.joinpath(vim.fn.expand '$MASON', 'packages', 'jdtls')
  local config_dir = vim.fs.joinpath(jdtls_installation_dir, 'config_')
  local uname = vim.uv.os_uname()
  if uname.sysname == 'Darwin' then
    config_dir = config_dir .. 'mac'
  elseif uname.sysname == 'Linux' then
    config_dir = config_dir .. 'linux'
  else
    config_dir = config_dir .. 'win'
  end
  local launcher_jar = vim.fn.glob(vim.fs.joinpath(jdtls_installation_dir, 'plugins', 'org.eclipse.equinox.launcher_*'))
  local root_dir = vim.fs.root(0, { '.git', 'mvnw', 'gradlew' })
  local project_name = vim.fn.fnamemodify(root_dir or vim.fn.getcwd(), ':p:h:t')
  local workspace_data_dir = vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath 'cache', '..', 'jdtls', 'workspace', project_name))
  local workspace_java_home = MiseWhere('java').path
  local encountered_versions = {}
  local mise_java_runtimes = {}
  for _, tbl in ipairs(vim.json.decode(vim.system({ 'mise', 'ls', '--json', 'java' }, { text = true }):wait().stdout)) do
    local number = tonumber(tbl.version:gsub('[a-z%-]', ''):gsub('%..*', ''), 10)
    if not vim.tbl_contains(encountered_versions, number) then
      mise_java_runtimes[#mise_java_runtimes + 1] = {
        name = 'JavaSE-' .. number,
        path = tbl.install_path .. '/',
      }
      encountered_versions[#encountered_versions + 1] = number
    end
  end

  -- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
  local config = {
    -- The command that starts the language server
    -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
    cmd = {

      -- 💀
      jdtls_rte_java,
      '-verbose',
      '-Xlog::file=' .. vim.fs.joinpath(vim.fn.stdpath 'log', 'jdtls.log'),
      '-Declipse.application=org.eclipse.jdt.ls.core.id1',
      '-Dosgi.bundles.defaultStartLevel=4',
      '-Declipse.product=org.eclipse.jdt.ls.core.product',
      '-Dlog.protocol=true',
      '-Dlog.level=ALL',
      '-Xmx1g',
      '--add-modules=ALL-SYSTEM',
      '--add-opens',
      'java.base/java.util=ALL-UNNAMED',
      '--add-opens',
      'java.base/java.lang=ALL-UNNAMED',
      '--enable-native-access=ALL-UNNAMED',

      -- 💀
      '-jar',
      launcher_jar,

      -- 💀
      '-configuration',
      config_dir,

      -- 💀
      -- See `data directory configuration` section in the README
      '-data',
      workspace_data_dir,
    },

    -- Here you can configure eclipse.jdt.ls specific settings
    -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
    -- for a list of options
    ---@module 'jdtls.setup'
    ---@type JdtSetupMainConfigOpts
    settings = {
      java = {
        project = {
          referencedLibraries = {
            sources = {},
          },
        },
        configuration = {
          runtimes = mise_java_runtimes,
        },
      },
      -- workspace_folders = { vim.uri_from_fname(workspace_data_dir) },
      settings = {
        java = {
          home = workspace_java_home,
        },
      },
      import = {
        gradle = {
          enabled = true,
        },
        maven = {
          enabled = true,
        },
        exclusions = {
          '**/node_modules/**',
          '**/.metadata/**',
          '**/archetype-resources/**',
          '**/META-INF/maven/**',
          '/**/test/**',
        },
      },
    },

    -- Language server `initializationOptions`
    -- You need to extend the `bundles` with paths to jar files
    -- if you want to use additional eclipse.jdt.ls plugins.
    --
    -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
    --
    -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
    init_options = {
      bundles = {
        vim.fn.glob(
          vim.fs.joinpath(
            os.getenv 'HOME',
            '.local',
            'share',
            'microsoft',
            'java-debug',
            'com.microsoft.java.debug.plugin',
            'target',
            'com.microsoft.java.debug.plugin-*.jar'
          )
        ),
      },
    },
  }
  return config
else
  return nil
end
