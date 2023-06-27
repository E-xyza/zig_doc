/// this is the function foo
pub fn foo(value: i32) i32 {
    return value + 1;
}

/// non-pub functions are ignored.
fn bar(value: i32) i32 {
    return value + 1;
}