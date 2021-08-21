## `sum` command
```
zigmod sum
```

- This will generate a `zigmod.sum` file with the blake3 hashes of your modules.

`zigmod.sum` may be checked into source control and there are plans to integrate it into the other commands in the future.

Running it on Zigmod (as of this writing) itself yields:
```
blake3-22472b867734926b202c055892fb0abb03f91556cd88998e2fe77addb003b1dd v/git/github.com/yaml/libyaml/tag-0.2.5
blake3-3c76436cde156ef2b92eca8e2a38cc2e07f23055422cfe903585bab8bcc47dd9 git/github.com/nektro/zig-ansi
blake3-b55d85de06e4921e85be2fb312c7e023729946be3ac73fe3229b58b173089df8 git/github.com/ziglibs/known-folders
blake3-42c3fae77ef41d2074e74de2d91cfc66bc591170494b10262dd2aeaea0b60cb5 git/github.com/nektro/zig-licenses
blake3-e3072f7fb47e86d53c9a1879e254ba1af55941153fd5f6752ec659b2f14854c9 git/github.com/truemedian/zfetch
blake3-fcb8e0116a8e32ab7a79e6622316d0be859f8813b5c5945c5536fb37ef165789 git/github.com/truemedian/hzzp
blake3-e6901bd7432450d5b22b01880cc7fa3fa2433e766a527206f18b29c67c1349bb git/github.com/alexnask/iguanaTLS
blake3-21f91e48333ac0ca7f4704c96352831c25216e7056d02ce24de95d03fc942246 git/github.com/MasterQ32/zig-network
blake3-030ebb03f1ed21122e681b06786bea6f2f1b810e8eb9f2029d0eee4f4fb3103f git/github.com/MasterQ32/zig-uri
blake3-1893709ffc6359c5f9cd2f9409abccf78a94ed37bb2c6dd075c603356d17c94b git/github.com/nektro/zig-json
blake3-09698753782139ab4877d08f33235170836f68b73e482b65cdee5637a6addf86 git/github.com/nektro/zig-range
blake3-dbbd8d54afa4f2ba93fe11396ca8137c85b4be358ffd106829668f74c9568739 git/github.com/nektro/zig-detect-license
blake3-20ceb9e27bdb93540e93006628fb94e0540f3f69a2304a8f73ad2989b8e27226 git/github.com/nektro/zig-licenses-text
blake3-cf68eaad66254b89c8bc18578f58607aa2e87ae59dd5696c2394eb5a0a31c455 git/github.com/nektro/zig-leven
blake3-10460da714f5c8436d09c268795597b0b2686ffc1e789c9f50366c2cbb0e1ff3 git/github.com/nektro/zig-fs-check
blake3-e476d1ceb5eb5bf59654c92fc5c0892a8ebd0bdb2ae502a67febe1c218d5e608 git/github.com/nektro/zig-inquirer
blake3-5bb722bdcd68e8d9edd356d6741910f60b24f33758bdd1f529fd8de8561c0d8f git/github.com/arqv/ini
blake3-4a3c0579bf3e970dd1f16e41ff024f292e32cde60a0d491bf91e75dfbe6edb2e git/github.com/marlersoft/zigwin32
```
