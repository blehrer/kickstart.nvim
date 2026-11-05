-- vscode-eslint / mason eslint: flat config repos (eslint.config.js) need useFlatConfig.
return {
  settings = {
    experimental = { useFlatConfig = true },
    workingDirectory = { mode = 'auto' },
    validate = 'on',
    run = 'onType',
  },
}
