#!/usr/bin/env bash
# fwcd kotlin-language-server: emit compile classpath (colon-separated on Unix).
# Install: ln -sf /path/to/this/script /your/gradle/root/kls-classpath
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
gradle_cmd() {
  if [[ -x "$root/gradlew" ]]; then
    "$root/gradlew" "$@"
  elif [[ -x "$root/../gradlew" ]]; then
    "$root/../gradlew" "$@"
  elif command -v gradle >/dev/null 2>&1; then
    gradle "$@"
  else
    echo "kls-classpath: no gradlew or gradle on PATH" >&2
    exit 1
  fi
}
init="$(mktemp "${TMPDIR:-/tmp}/kls-classpath.XXXXXX")"
trap 'rm -f "$init"' EXIT
cat >"$init" <<'GROOVY'
gradle.projectsLoaded {
    rootProject.allprojects { p ->
        p.tasks.register("klsEmitClasspath") {
            doLast { println p.sourceSets.main.compileClasspath.asPath }
        }
    }
}
GROOVY
(cd "$root" && gradle_cmd -q -I "$init" klsEmitClasspath)
