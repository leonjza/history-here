# history-here

Zsh plugin that binds `^G` to quickly toggle the current shell history file location.

## installation

Oh My Zsh: clone or symlink this repo into `~/.oh-my-zsh/custom/plugins/history-here`, then add it to your plugins array:

```zsh
plugins=(... history-here)
```

Zim: add a zmodule entry to your `.zimrc`. It will be autodownloaded on next shell start, or you can run `zimfw install`/`zimfw update`:

```zsh
zmodule leonjza/history-here
```

Manual source (after cloning):

```zsh
source /path/to/history-here/history-here.plugin.zsh
```

## configuration

You can configure automatic isolation of shell history by setting the `HISTORY_HERE_AUTO_DIRS` array. Entries are treated as prefixes for a single path component, and history is stored at the matched component root. This keeps history anchored to the project root even when you are in subdirectories or start a new shell there.

Manual toggling with `^G` always uses the current directory (`$PWD`) so you can intentionally isolate history at any depth.

```zsh
export HISTORY_HERE_AUTO_DIRS=(/Users/foo/clients ~/work)
```

Examples:

- `/Users/foo/clients/acme/another` uses `/Users/foo/clients/acme/.zsh_history`
- `~/work/alpha/src` uses `~/work/alpha/.zsh_history`

Note, if you set a small value of something like `pa`, any directory with a component starting with `pa` under the same parent directory would trigger history isolation.
