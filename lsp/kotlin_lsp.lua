-- JetBrains kotlin-lsp (Gradle/Kotlin 2.3+). fwcd kotlin_language_server ships Kotlin 2.1 and
-- breaks on Gradle 9.x stdlib 2.3 metadata; keep it out of ensure_installed / automatic_enable.
return {
  filetypes = { 'kotlin', 'kotlin.gradle' },
  cmd_env = vim.fn.environ(),
}
