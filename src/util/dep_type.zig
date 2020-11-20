//
//

pub const DepType = enum {
    git,        // https://git-scm.com/
    hg,         // https://www.mercurial-scm.org/
};

pub const GitVersionType = enum {
    branch,
    tag,
    commit,
};
