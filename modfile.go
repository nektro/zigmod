package main

import (
	"io/ioutil"
	"os"
	"strings"

	"github.com/nektro/go-util/util"
	"gopkg.in/yaml.v2"
)

// ModFile is
type ModFile struct {
	Name string `yaml:"name"`
	Main string `yaml:"main"`
	Deps []Dep  `yaml:"dependencies"`
}

// this is the string enum because Go doesnt have those
var (
	DepTypeGit  = "git" // https://git-scm.com/
	AllDepTypes = []string{
		DepTypeGit,
	}
)

// Dep is
type Dep struct {
	Type string `yaml:"type"`
	Path string `yaml:"path"`
}

func (s *Dep) cleanPath() string {
	p := s.Path
	p = strings.TrimPrefix(p, "https://")
	p = strings.TrimPrefix(p, "http://")
	p = strings.TrimSuffix(p, ".git")
	p = strings.Join(strings.Fields(strings.Join(strings.Split(p, "/"), " ")), "/")
	return p
}

func readModFile(fpath string) *ModFile {
	f, err := os.Open(fpath)
	util.DieOnError(err)
	bys, _ := ioutil.ReadAll(f)
	m := new(ModFile)
	yaml.Unmarshal(bys, &m)
	return m
}
