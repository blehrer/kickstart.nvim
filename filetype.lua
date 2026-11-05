vim.filetype.add({
  pattern = {
    ['.*/roles/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/playbooks/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/tasks/.*%.ya?ml'] = 'yaml.ansible',
    ['%.gitlab%-ci%.ya?ml'] = 'yaml.gitlab',
  },
  filename = {
    ['execution-environment.yml'] = 'yaml.ansible',
    ['execution-environment.yaml'] = 'yaml.ansible',
    ['playbook.yaml'] = 'yaml.ansible',
    ['playbook.yml'] = 'yaml.ansible',
    ['build.gradle.kts'] = 'kotlin.gradle',
    ['build.gradle'] = 'groovy.gradle',
  },
})
