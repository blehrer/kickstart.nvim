local workspace = require('nx.workspace')

assert(workspace.normalize_remote('git@GitHub.com:Org/Repo.git') == 'git@github.com:Org/Repo')
assert(workspace.normalize_remote('https://GitHub.com/Org/Repo.git') == 'https://github.com/org/repo')

print('nx: 2 checks passed')
