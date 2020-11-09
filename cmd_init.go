package main

import (
	"bytes"
	"errors"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/nektro/go-util/util"
	"github.com/spf13/cobra"
)

func init() {
	last := func(a []string) string {
		if len(a) == 0 {
			return ""
		}
		return a[len(a)-1]
	}
	tryIndex := func(a []string, n int) string {
		if n >= len(a) {
			return ""
		}
		return a[n]
	}
	detectPkgName := func(arg string) string {
		if len(arg) > 0 {
			return arg
		}
		n, _ := filepath.Abs("./")
		n = last(strings.Split(n, "/"))
		n = strings.TrimPrefix(n, "zig-")
		assert(len(n) > 0, "name may not be an empty string")
		return n
	}
	detectMainFile := func(arg string) string {
		if len(arg) > 0 {
			argR, err := filepath.Abs(arg)
			util.DieOnError(err)
			if !util.DoesFileExist(argR) {
				util.DieOnError(errors.New("specified entry point file does not exist: " + arg))
			}
			if !strings.HasSuffix(arg, ".zig") {
				util.DieOnError(errors.New("main entry point must be a .zig file"))
			}
			cwd, _ := os.Getwd()
			argR = strings.TrimPrefix(argR, cwd)[1:]
			argR = strings.ReplaceAll(argR, "\\", "/")
			return argR
		}
		if util.DoesFileExist("./src/main.zig") {
			return "src/main.zig"
		}
		util.DieOnError(errors.New("unable to determine package entry point"))
		return ""
	}
	rootCmd.AddCommand(&cobra.Command{
		Use:   "init",
		Short: "Initialize a new package.",
		Long:  `zigmod init [name] [main_file]`,
		Run: func(cmd *cobra.Command, args []string) {
			buf := new(bytes.Buffer)

			name := detectPkgName(tryIndex(args, 0))
			fmt.Fprintln(buf, "name:", name)

			mainf := detectMainFile(tryIndex(args, 1))
			fmt.Fprintln(buf, "main:", mainf)

			fmt.Fprintln(buf, "dependencies:")
			f, err := os.Create("./zig.mod")
			util.DieOnError(err)

			fmt.Fprint(f, buf.String())
			log.Println("Initialized a new package named", name, "with entry point", mainf)
		},
	})
}
