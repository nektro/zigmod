## `aq modfile` command
```
zigmod aq modfile <version>
```

This is a temporary command that can print the corresponding `zig.mod` yaml for a new version.

If on the details page for a package version, the string `<version>` is expecting is the path of the url after the domain. So for the version https://aquila.red/1/nektro/iana-tlds/v0.2, the version ID is `1/nektro/iana-tlds/v0.2`.

### Example Output
`$ zigmod aq modfile 1/nektro/iana-tlds/v0.2`
```
  - src: http https://aquila.red/1/nektro/iana-tlds/v0.2.tar.gz _ 0 2
    version: sha256-d2e50438ad3ab45ee56b13f285234bed0738c2cb7c1c7023da8489b48ecf876f
```
