
func assert(x bool, msg string) {
	util.DieOnError(util.Assert(x, msg))
}
