## `sum` command
```
zigmod sum
```

- This will generate a `zig.sum` file with the blake3 hashes of your modules.

`zig.sum` may be checked into source control and there are plans to integrate it into the other commands in the future.

Running it on Zigmod (as of this writing) itself yields:
```
blake3-22472b867734926b202c055892fb0abb03f91556cd88998e2fe77addb003b1dd v/git/github.com/yaml/libyaml/tag-0.2.5
blake3-c9f1cfe1c2bc8f0f7886a29458985491ea15f74c78275c28ce2276007f94d492 v/git/github.com/nektro/zig-ansi/commit-25039ca
blake3-74924ab693ea7730d53839a45805584561fdfc99872f8c307121089070ef6283 v/git/github.com/ziglibs/known-folders/commit-f0f4188
blake3-35adb816bfc0db5e1cc156a2dc61de9b9f15a6e64879cbd0dc962e3c99601850 v/git/github.com/Vexu/zuri/commit-41bcd78
blake3-9bc6fdab07a606e3a99c9480e15e62aacc0cf078f3b233bdbb54d4e16acbb942 v/git/github.com/alexnask/iguanaTLS/commit-58f72f6
blake3-87a1481d3affd6b70f4d20c69096a36f3fc55859ec6ed2e93df3c3913a86640f v/git/github.com/nektro/zig-licenses/commit-a15ef9b
```
