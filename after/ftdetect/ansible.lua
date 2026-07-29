vim.filetype.add({
  pattern = {
    ['.*/roles/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/playbooks/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
  },
  filename = {
    ['execution-environment.yml'] = 'yaml.ansible',
    ['execution-environment.yaml'] = 'yaml.ansible',
    ['playbook.yaml'] = 'yaml.ansible',
    ['playbook.yml'] = 'yaml.ansible',
  },
})
