# Zigmod Tutorial

This guide will go over the various common workflows done while using Zigmod as well as how its design goals fit into them.

## Initialize a new project
To get started you'll want to navigate to a new folder and run these commands.

```
git init
zig init-exe
zigmod init
```

Zigmod's init wizard will ask you if the current project is an application or a library and setup some initial properties in your `zig.mod`. However, if you do plan to have a project that is both a library to be used in other Zig projects and an application itself, don't fret. For Zigmod is able to support both of thses configurations simultaneously.

The wizard will also ask if you'd like it setup any additional metadata files such as `.gitignore` or `LICENSE` for you.

> Ref: See [`zigmod init`](./commands/init.md) for more info.

---
## Running `zigmod fetch`
This command will inspect your `zig.mod` and download any new dependencies as well as pulling updates for any ones already download. It will recursively do this for your entire tree until it is full constructed which will culminate in the generation of two output files: `deps.zig` and `zigmod.lock`.

`deps.zig` we will use in the next step integrating with the [Zig Build System](https://ziglang.org/documentation/master/#Zig-Build-System). [Learn more](./deps.zig.md).

`zigmod.lock` is a way to enable [Reproducible builds](https://reproducible-builds.org/) and often used in CI environments. [Learn more](./commands/ci.md).

Add `--no-update` if you do want it to fetch remote updates and only regenerate `deps.zig`.

> Ref: See [`zigmod fetch`](commands/fetch.md) reference for more info.

---
## Integrating with `build.zig`
```diff
 const std = @import("std");
+const deps = @import("./deps.zig");

 pub fn build(b: *std.build.Builder) void {
     const target = b.standardTargetOptions(.{});

     const mode = b.standardReleaseOptions();

     const exe = b.addExecutable("hello", "src/main.zig");
     exe.setTarget(target);
     exe.setBuildMode(mode);
+    deps.addAllTo(exe);
     exe.install();
```

---
## Adding a dependency
The core of expandability, it is possible to add dependencies to your project. How exactly, depends on where you're sourcing the information from.

- Aquila
     - One place packages can be sourced from is https://aquila.red/. In order to add them to your project, you will obtain its ID in the form `1/truemedian/hzzp` and then run `zigmod aq add <package>`.

- ZPM
     - https://zig.pm/ is another supported pacakge index. You may add packages from ZPM with `zigmod zpm add <pacakge>`.

- Other/Git
     - Zigmod supports adding any Git repository as a dependency. This is done by manually editing your `zig.mod` and adding a line under either the `dependencies` or `dev_dependencies` keys. For example, adding a line with this contents would add `apple_pie` to your project: `  - src: git https://github.com/Luukdegram/apple_pie`. The URL field may be any valid Git url that you would pass to `git clone`.

- Other/System Library
     - System libraries are similar to Git dependencies, but instead of `git <url>` it is `system_lib <name>`.

- Other/HTTP
     - Http tarballs are also allowed and follow a similar pattern as Git dependencies but use the `http` type. One thing to note is that it is recomended to add a hash verification after your tarball URL so that zigmod may assert whether or not it has been downloaded already to prevent unnecessary trips to the network. Hash verification versions are placed after the URL and in the form `type-string` such as `sha256-8ff0b79fd9118af7a760f1f6a98cac3e69daed325c8f9f0a581ecb62f797fd64`. They may also be placed in their own `version` key instead of `src`. The available hash algorithms are `blake3`, `sha256`, `sha512`.

- Other/Mercurial
     - Mercurial follows the same rules as Git dependencies and uses the `hg` Dep type.

---
## Using build-time dependencies in `build.zig`
Dependencies that are added to `dev_dependencies` will additionally be exposed in `deps.zig` generation under the `imports` namesapce. https://github.com/Snektron/vulkan-zig is a common example of a package that can be used with Zigmod as a build-time dependency.

```zig
const deps = @import("./deps.zig");
const vkgen = deps.imports.vulkan_zig;

pub fn build(b: *Builder) void {

    const exe = b.addExecutable("my-executable", "src/main.zig");

    const gen = vkgen.VkGenerateStep.init(b, "path/to/vk.xml", "vk.zig");

    exe.addPackage(gen.package);
}
```

---
## Contributing to dependency upstream
When using Git dependencies, Zigmod streamlines the process of contributing back fixes and improvements to your upstream. This is due to the fact that Zigmod will preserve the `.git` folder when cloning so that you may work with it.

Suppose we have the package https://github.com/octocat/zig-hello.

Zigmod will `git clone` its contents to `.zigmod/deps/git/github.com/octocat/zig-hello`. If we find a bug or want to contribute a new feature we may navigate to this directory, edit any files we choose and make commits.

Then fork the repository on `github.com` or wherever it is hosted and add a local remote so that you have something to push to. `git remote add fork https://github.com/you/zig-hello`.

Then push your local changes with `git push fork master` and create your pull request.

---
## Using Zigmod in Github Actions
```yml
- uses: nektro/actions-setup-zigmod
```

This will allow your Github Action task to use the various Zigmod commands. `zigmod ci` is recommended for this use case as it is similar to `zigmod fetch` but will fetch the versions only listed in your `zigmod.lock`.

---
## Publishing your project on Aquila
https://github.com/nektro/aquila is a package index software and CI system designed to work in conjunction with Zigmod.

> Note: I, @nektro, host a public instance at https://aquila.red/ available for anyone to use. However Aquila can be self hosted and the only difference in the following instructions will be the domain name.

Navigating to https://aquila.red/ will show you the homepage with recent pacakges and most starred ones.

Clicking the "Login" button will bring you to https://aquila.red/dashboard which will show you a list of your currently imported pacakges. The login screen will prompt you to authorize with an identity provider and ask you for webhook permissions. This is so that aquila can listen for new updates and automatically test them for the CI.

The main nav will contain a link to https://aquila.red/import. Listed will be all of your not-imported Zig projects. Clicking "Select" will not immediately navigate the page in most browsers as the server will attempt to clone and verify your repository. Please be patient while it loads.

Once it brings you to the package page it will now be available for discovery and be automatically included for testing.

---
## Auditing your project's licenses
This can come in handy for users and organizations alike. The `zigmod license` command will show you a list of the licenses involved in a project (deeply) and present them nicely grouping similar licenses together and providing a link to the license test for any projects that use a valid SPDX license identifier.

Given the project https://github.com/kristoff-it/bork, at the time of writing that output would look like the following:

![image](https://user-images.githubusercontent.com/5464072/130309694-180da454-553d-4136-a7ac-0f4f3f5ecf3d.png)

> Ref: See [`zigmod license`](commands/license_.md) reference for more info.

---
## Verifying dependency integrity

> Ref: See [`zigmod sum`](commands/sum.md) reference for more info.

---
## Installing online programs to your local machine

> Ref: See [`zigmod aq install`](commands/aq_install.md) reference for more info.
