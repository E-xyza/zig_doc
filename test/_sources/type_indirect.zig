const aaa = struct {
    baz: i32,
    pub const bar: i32;
    pub fn quux(v: foo) i32 {
        return v.baz + 1;
    }
};

/// this is the foo type.
pub const foo = aaa;