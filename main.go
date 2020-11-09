package main

import (
	"os/exec"
	"strings"

	"github.com/nektro/go-util/util"
	"github.com/spf13/cobra"
)

// Version takes actual string in from build_all.sh
const Version = "vMASTER"

func main() {
	err := rootCmd.Execute()
	util.DieOnError(err)
}

var rootCmd = &cobra.Command{
	Use:   "zigmod",
	Short: "Zigmod is a package manager for Zig.",
	Long:  `Get documentation, binaries, and more from https://github.com/nektro/zigmod.`,
	Run: func(cmd *cobra.Command, args []string) {
		// Do Stuff Here
	},
}

func assert(x bool, msg string) {
	util.DieOnError(util.Assert(x, msg))
}

func runCmd(dir, cm string, args ...string) {
	c := exec.Command(cm, args...)
	if len(dir) > 0 {
		c.Dir = dir
	}
	util.DieOnError(c.Run())
}

func join(a ...string) string {
	return strings.Join(a, " ")
}
