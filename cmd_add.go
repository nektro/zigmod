package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/nektro/go-util/arrays/stringsu"
	"github.com/nektro/go-util/util"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v2"
)

func init() {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "add",
		Short: "Add a new dependency to your project",
		Long:  `zigmod add <type> <path>`,
		Run: func(cmd *cobra.Command, args []string) {
			assert(len(args) >= 1, "missing package <type> parameter")
			assert(len(args) >= 2, "missing package <path> parameter")

			dept := args[0]
			path := args[1]

			assert(stringsu.Contains(AllDepTypes, dept), "provided <type> parameter is not a valid dependency type")

			f, err := os.Open("./zig.mod")
			util.DieOnError(err)
			bys, _ := ioutil.ReadAll(f)

			m := new(ModFile)
			yaml.Unmarshal(bys, &m)

			for _, item := range m.Deps {
				if item.Type == dept && item.Path == path {
					assert(false, "dependency already added, skipping!")
				}
			}
			m.Deps = append(m.Deps, Dep{dept, path})

			f.Close()
			f, err = os.Create("./zig.mod")
			util.DieOnError(err)
			d, _ := yaml.Marshal(m)
			fmt.Fprint(f, string(d))
			log.Println("Successfully added", path)
		},
	})
}
