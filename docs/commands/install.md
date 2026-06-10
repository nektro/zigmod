## `install` command

```
zigmod install
```

Installs a command from any remote compatible repository into `$HOME/.zigmod/bin/`.

```
zigmod install [git|hg|http] [url]
```

- The `git` type for [Git](https://git-scm.com/) requires having `git` in $PATH.
- The `hg` type for [Mercurial](https://www.mercurial-scm.org/) requires having `hg` in $PATH.
- The `http` type requires having `wget` and ( `tar` or `unzip` ) in `$PATH`.

`[url]` may be the link to any remote repository that contains a Zig project with a `zigmod.yml` manifest. If your project currently does not have one, you may create one using [`zigmod init`](./init.md).

```
$ zigmod install git https://github.com/nektro/zigmod
debug: modpath: /home/me/.cache/zigmod/deps/git/github.com/nektro/zigmod
debug: argv: { /home/me/.local/share/zig/0.16.0/zig, build, --prefix, /home/me/.zigmod }
info: success!
```
