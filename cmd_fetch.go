package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"strings"

	"github.com/mitchellh/go-homedir"
	"github.com/nektro/go-util/util"
	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "fetch",
		Short: "Read the current zig.mod and generate a zig.mod.zig that can be imported in build.zig.",
		Long:  `zigmod fetch`,
		Run: func(cmd *cobra.Command, args []string) {
			hd, err := homedir.Dir()
			util.DieOnError(err)
			dir := hd + "/.cache/zigmod/deps"
			fetchDeps(dir, "./zig.mod")

			out, err := os.Create("./deps.zig")
			fmt.Fprintln(out, `const std = @import("std");`)
			fmt.Fprintln(out, `const Pkg = std.build.Pkg;`)
			fmt.Fprintln(out, ``)
			fmt.Fprintln(out, `const home = "`+hd+`";`)
			fmt.Fprintln(out, `const cache = home ++ "/.cache/zigmod/deps";`)
			fmt.Fprintln(out, ``)
			fmt.Fprint(out, `pub const packages = `)
			printDeps(out, dir, readModFile("./zig.mod"), 0)
			fmt.Fprintln(out, `;`)
		},
	})
}

func fetchDeps(dpath, fpath string) {
	m := readModFile(fpath)
	for _, item := range m.Deps {
		switch item.Type {
		case DepTypeGit:
			log.Println("fetch:", m.Name+":", item.Type+":", item.Path)
			p := dpath + "/" + item.cleanPath()
			if !util.DoesDirectoryExist(p) {
				runCmd("", "git", "clone", item.Path, p)
			} else {
				runCmd(p, "git", "fetch")
				runCmd(p, "git", "pull")
			}
		default:
			assert(false, join("invalid dependency type detected:", item.Type, "in package:", m.Name))
		}
		//
		switch item.Type {
		case DepTypeGit:
			p := dpath + "/" + item.cleanPath() + "/zig.mod"
			fetchDeps(dpath, p)
		}
	}
}

func printDeps(w io.Writer, dir string, m *ModFile, tabs int) {
	if len(m.Deps) == 0 {
		fmt.Fprint(w, `null`)
		return
	}
	fmt.Fprintln(w, `&[_]Pkg{`)
	t := "    "
	r := strings.Repeat(t, tabs)
	for _, item := range m.Deps {
		switch item.Type {
		default:
			continue
		case DepTypeGit:
			p := dir + "/" + item.cleanPath()
			n := readModFile(p + "/zig.mod")
			fmt.Fprintln(w, r+t+`Pkg{`)
			fmt.Fprintln(w, r+t+t+`.name = "`+n.Name+`",`)
			fmt.Fprintln(w, r+t+t+`.path = cache ++ "/`+item.cleanPath()+`/`+n.Main+`",`)
			fmt.Fprint(w, r+t+t+`.dependencies = `)
			printDeps(w, dir, n, tabs+2)
			fmt.Fprintln(w, ",")
			fmt.Fprintln(w, r+t+`},`)
		}
	}
	fmt.Fprint(w, r+`}`)
}
