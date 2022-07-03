use std::env;

mod lexer;

fn main() {
    let args: Vec<String> = env::args().collect();
    let _ = lexer::lex(args.get(1).unwrap());
    println!("Hello, world!");
}
