/// this is the foo type.
pub const foo = struct {
    /// this is the baz field.
    baz: i32,
    /// this is the bar const.
    pub const bar: i32 = 123;

    const mlem: i32 = 123;  // note this won't be documented

    /// this is the quux function.
    pub fn quux(v: foo) i32 {
        return v.baz + 1;
    }

    /// this shouldn't be documented:
    fn blep(v: foo) i32 {
        return v.baz + 2;
    }
};