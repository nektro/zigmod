## Zigmod Principles
Zigmod is a prototype package manager for Zig. An official one will eventually be made so I wanted to add this page to the docs to go over some of the guiding principles used in this project. Some are general good practice for app development but there will be added context in how they apply to making a package manager.

### 1. Be declarative
`zig.mod` is a static Yaml file that does not contain any Zig code. Placing packages' definition in its own file (say as opposed to in `build.zig`) was an intentional decision from the start to not allow packages to run arbitrary code on the developer's machine. A maintainer's computer is an arguably much more high risk attack surface so the trust of code should be kept to a minimum. Given that the environment may contain API/ssh/etc keys that provide access to things far wider than just the user's computer.

### 2. Be Immutable/Avoid the network as much as possible
The network is slow and unreliable. So we should cache only what we need and avoid fetching unchanged data. This is achieved from a user's perspective by using versions on your dependencies that dont change. For example tags or commits when using git, or specifying a hash when using http.

### 3. Keep debugging easy
Dependencies are stored based on the path they were downloaded from (as opposed to a hash or their random package ID).

Example: `.zigmod/deps/v/git/github.com/Hejsil/zig-clap/commit-e00e902/clap.zig`.

This ensures that stack traces are still readable.

### 4. Follow the Zen
https://ziglang.org/documentation/master/#Zen
