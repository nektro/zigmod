## `sum` command
```
zigmod sum
```

- This will generate a `zig.sum` file with the blake3 hashes of your modules.

`zig.sum` may be checked into source control and there are plans to integrate it into the other commands in the future.

Running it on Zigmod (as of this writing) itself yields:
```
blake3-22472b867734926b202c055892fb0abb03f91556cd88998e2fe77addb003b1dd v/git/github.com/yaml/libyaml/tag-0.2.5
blake3-c9f1cfe1c2bc8f0f7886a29458985491ea15f74c78275c28ce2276007f94d492 git/github.com/nektro/zig-ansi
blake3-e7d7348c05ca69eab697c8a902126b6dcb49ac396ef22750b79a3e575fb74b0e git/github.com/ziglibs/known-folders
blake3-77ce43ca22debd0e34b3b6b8dfc251e4242916b5eaf06bdefababda192bdec82 git/github.com/nektro/zig-licenses
blake3-22e6fe29852808cd9862d1f9677f2e7c2b23e27321ba4840ba6e536912ab4ac1 git/github.com/truemedian/zfetch
blake3-3f88dfd50f56af596aced2819073c74a8d10cdba5a8c1be21e8c5d56086c0587 git/github.com/truemedian/hzzp
blake3-2b3f7cc5934d1da058d5413a991eab370796bbf81fea40660a8f300af598970b git/github.com/alexnask/iguanaTLS
blake3-900f4c0cb1e7078b8e7a3f022efe81444cd353a1788eb520683512b7815b788a git/github.com/MasterQ32/zig-network
blake3-754b1b7e57b716ca042a9fc5c262e4931a804bddd52df695ec2b5476d0df0005 git/github.com/MasterQ32/zig-uri
blake3-155960bc30c27ccee4f6f10cfb0398d1bcec367abaabb16f18de6176bd92112c git/github.com/nektro/zig-json
```
