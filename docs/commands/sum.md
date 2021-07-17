## `sum` command
```
zigmod sum
```

- This will generate a `zigmod.sum` file with the blake3 hashes of your modules.

`zigmod.sum` may be checked into source control and there are plans to integrate it into the other commands in the future.

Running it on Zigmod (as of this writing) itself yields:
```
blake3-22472b867734926b202c055892fb0abb03f91556cd88998e2fe77addb003b1dd v/git/github.com/yaml/libyaml/tag-0.2.5
blake3-7fc0b46397932ea1f0726d42289606ca118cc745d88dd87c0d6a377ba7c6569f git/github.com/nektro/zig-ansi
blake3-35a1c330c9999876e71418a7d43ad24ca7d1e23c3b5576e5cb75667e3392cc10 git/github.com/ziglibs/known-folders
blake3-6e3f314a9f1b80e65f80ec48fe22cedd58821a35235de388948366b531de9d40 git/github.com/nektro/zig-licenses
blake3-98617af380bdf5bf90efd27f5960041418edcfba14f282d8f3dac1dba96f965f git/github.com/truemedian/zfetch
blake3-98982125d0fbedc62e179e62081d2797a2b8a3623c42f9fd5d72cd56d6350714 git/github.com/truemedian/hzzp
blake3-e6901bd7432450d5b22b01880cc7fa3fa2433e766a527206f18b29c67c1349bb git/github.com/alexnask/iguanaTLS
blake3-21f91e48333ac0ca7f4704c96352831c25216e7056d02ce24de95d03fc942246 git/github.com/MasterQ32/zig-network
blake3-030ebb03f1ed21122e681b06786bea6f2f1b810e8eb9f2029d0eee4f4fb3103f git/github.com/MasterQ32/zig-uri
blake3-1893709ffc6359c5f9cd2f9409abccf78a94ed37bb2c6dd075c603356d17c94b git/github.com/nektro/zig-json
blake3-09698753782139ab4877d08f33235170836f68b73e482b65cdee5637a6addf86 git/github.com/nektro/zig-range
```
