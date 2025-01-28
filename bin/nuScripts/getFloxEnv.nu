def main [] {
    let active_envs = (try { flox envs --active --json | from json } catch { [] })
    if ($active_envs | is-empty) {
        echo ""
    } else {
        echo ($active_envs | get 0.pointer.name)
    }
}
