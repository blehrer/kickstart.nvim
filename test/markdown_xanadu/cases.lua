return {
  parse = {
    {
      file = 'links/mixed-syntax.md',
      scan = true,
      expect_count = 4,
      expect_paths = { 'targets/alpha', '../targets/beta.md', '../targets/nested/deep/note.md' },
    },
    {
      file = 'links/wiki-deep.md',
      scan = true,
      expect_count = 6,
      expect_paths = { 'targets/alpha', 'targets/beta', 'graphs/chain-mid' },
    },
    {
      file = 'links/wiki-basic.md',
      scan = true,
      expect_count = 3,
    },
    {
      file = 'edge-cases/escaped-and-literal.md',
      scan = true,
      expect_count = 1,
      expect_paths = { 'targets/alpha' },
    },
    {
      file = 'links/mixed-syntax.md',
      line = 2,
      col = 33,
      expect = { kind = 'link', path = 'targets/alpha' },
    },
  },
  resolve = {
    {
      from = 'links/wiki-deep.md',
      link = { path = 'targets/alpha', heading = 'Section Two' },
      expect = { file_suffix = 'targets/alpha.md', line = 9, col = 0 },
    },
    {
      from = 'links/wiki-deep.md',
      link = { path = 'targets/alpha', block_id = 'block-beta' },
      expect = { file_suffix = 'targets/alpha.md', line = 19, col = 0 },
    },
    {
      from = 'links/wiki-deep.md',
      link = { path = 'targets/alpha', block_id = 'block-alpha' },
      expect = { file_suffix = 'targets/alpha.md', line = 15, col = 0 },
    },
    {
      from = 'links/standard-md.md',
      link = { path = '../targets/alpha.md' },
      expect = { file_suffix = 'targets/alpha.md', line = 1, col = 0 },
    },
    {
      from = 'edge-cases/missing-target.md',
      link = { path = 'does-not-exist' },
      expect = nil,
    },
  },
  backlinks = {
    {
      file = 'targets/alpha.md',
      expect_files = {
        'graphs/hub.md',
        'links/wiki-deep.md',
        'views/sidebar-tour.md',
      },
    },
  },
  registry = {
    {
      file = 'views/sidebar-tour.md',
      expect_entries = 8,
    },
  },
  gutter = {
    {
      left_row = 5,
      right_row = 12,
      expect_chars = { '┐', '│', '┘' },
    },
    {
      left_row = 8,
      right_row = 8,
      expect_chars = { '─' },
    },
  },
}
