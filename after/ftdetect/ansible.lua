vim.filetype.add {
  pattern = {
    -- Matches any .yml/.yaml file inside a folder named 'roles' or 'playbooks'
    ['.*/roles/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/playbooks/.*%.ya?ml'] = 'yaml.ansible',
    -- Specific pattern for tasks files
    ['.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
  },
  filename = {
    ['execution-environment.yml'] = 'yaml.ansible',
    ['execution-environment.yaml'] = 'yaml.ansible',
    ['playbook.yaml'] = 'yaml.ansible',
    ['playbook.yml'] = 'yaml.ansible',
  },
}
