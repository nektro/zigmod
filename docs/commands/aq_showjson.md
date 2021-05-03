## `aq showjson` command
```
zigmod aq showjson <query>
```

This is a meta command for obtaining raw json from Aquila servers and ideally paired with [`jq`](https://stedolan.github.io/jq/).

A number of extra functionality can be gained by composing this command with other utilities. Some examples are shown below:

----

- List a user's published packages:
```
zigmod aq showjson 1/nektro | jq '.pkgs[].name'
```

- List a package's published versions:
```
zigmod aq showjson 1/nektro/iana-tlds | jq -c '.versions[] | [.real_major, .real_minor] | "v\(.[0]).\(.[1])"'
```
