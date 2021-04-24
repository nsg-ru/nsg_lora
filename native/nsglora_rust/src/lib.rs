#[rustler::nif]
fn add(a: i64, b: i64) -> i64 {
    a + b
}

#[rustler::nif]
fn mul(a: i64, b: i64) -> i64 {
    a * b
}

rustler::init!("Elixir.NsgLora.Rust", [add, mul]);
