use std::{fs::File, io::Read};

type TokenRes = Result<(Pos, Token), CompErr>;

/// Represents a position in the source code
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Pos {
    pub offset: usize,
}

impl Pos {
    pub fn new(offset: usize) -> Pos {
        Pos { offset }
    }
}

pub struct LexContext<'a> {
    pub content: &'a [u8],
    // Offset for use by the lexer
    pub offset: usize,
    // Used for the tokenizer stack
    pub tok_stack: Vec<(Pos, Token)>,
}

impl LexContext<'_> {
    pub fn pos(&self) -> Pos {
        Pos::new(self.offset)
    }

    pub fn from_bytes<'a>(content: &'a [u8]) -> LexContext<'a> {
        LexContext {
            content: content,
            offset: 0,
            tok_stack: vec![],
        }
    }

    pub fn from_string<'a>(content: &'a String) -> LexContext<'a> {
        LexContext::from_bytes(content.as_bytes())
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct CompErr {
    pub pos: Option<Pos>,
    pub message: String,
}

impl CompErr {
    pub fn err<T>(pos: Pos, message: String) -> Result<T, CompErr> {
        Err(CompErr {
            pos: Some(pos),
            message: message,
        })
    }
}

#[derive(Clone, Debug, PartialEq)]
pub enum Token {
    IntValue(u16), // Max size of number is 16 bits (absolute memory address)
    Label(String),
    Id(String),
    Hash,
    Comma,
    LParen,
    RParen,
    Newline,
    Eof,
}

/// Lex the file at the given path
pub fn lex(file_path: &String) -> Result<Vec<(Pos, Token)>, CompErr> {
    let bytes = get_file_as_byte_vec(file_path);
    let mut c = LexContext::from_bytes(bytes.as_slice());
    let _ = pop_tok(&mut c);

    Ok(vec![])
}

fn get_file_as_byte_vec(filename: &String) -> Vec<u8> {
    let mut f = File::open(&filename).expect("no file found");
    let metadata = std::fs::metadata(&filename).expect("unable to read metadata");
    let mut buffer = vec![0; metadata.len() as usize];
    f.read(&mut buffer).expect("buffer overflow");
    buffer
}

// Returns an error for invalid tokens
// Returns Token::Eof for Eof (considered a valid token)
fn pop_tok(c: &mut LexContext) -> TokenRes {
    match c.tok_stack.pop() {
        None => {}
        Some(next) => return Ok(next),
    };
    consume_hs(c);

    let ch = if let Some(c) = c.content.get(c.offset) {
        *c as char
    } else {
        return Ok((c.pos(), Token::Eof));
    };

    match ch {
        '\n' => {
            c.offset += 1;
            Ok((c.pos(), Token::Newline))
        }
        '0'..='9' => get_tok_int_dec(c),
        '%' => {
            c.offset += 1;
            get_tok_int_bin(c)
        }
        '$' => {
            c.offset += 1;
            get_tok_int_hex(c)
        }
        '_' | 'a'..='z' | 'A'..='Z' => get_tok_word(c),
        ch => get_tok_symbol(c, ch),
    }
}

/// Parsed word-like tokens. Includes keywords, IDs, and labels
fn get_tok_word(c: &mut LexContext) -> Result<(Pos, Token), CompErr> {
    let pos = c.pos();
    let slice = id_slice(pos, &c.content, c.offset)?;
    c.offset += slice.len();

    // Safe to assume it's valid utf8 since we enforce ASCII
    let name: String = slice.to_string();
    let tok = if c.offset >= c.content.len() {
        Token::Id(name)
    } else {
        let ch = c.content.get(c.offset);

        if ch == Some(&(':' as u8)) {
            c.offset += 1;
            Token::Label(name)
        } else {
            Token::Id(name)
        }
    };
    Ok((pos, tok))
}

fn get_tok_symbol(c: &mut LexContext, ch: char) -> TokenRes {
    let pos = c.pos();
    let tok = match ch {
        '#' => Token::Hash,
        ',' => Token::Comma,
        '(' => Token::LParen,
        ')' => Token::RParen,
        _ => return CompErr::err(c.pos(), format!("Unexpected character: {}", ch)),
    };
    c.offset += 1;
    Ok((pos, tok))
}

fn get_tok_int_dec(c: &mut LexContext) -> TokenRes {
    let pos = c.pos();
    let current_word = id_slice(pos, &c.content, c.offset)?;

    let mut value: u32 = 0;
    let mut significance = 1;

    for c in current_word.bytes().rev() {
        if c > '9' as u8 || c < '0' as u8 {
            return CompErr::err(pos, format!("Invalid int literal: {}", current_word));
        }
        let x = c as u32 - '0' as u32;
        value += x * significance;
        significance *= 10;

        if value > u16::MAX as u32 {
            return CompErr::err(pos, format!("Invalid decimal literal: {}", current_word));
        }
    }
    c.offset += current_word.len();
    Ok((pos, Token::IntValue(value as u16)))
}

fn get_tok_int_bin(c: &mut LexContext) -> TokenRes {
    let pos = c.pos();
    let current_word = id_slice(pos, &c.content, c.offset)?;

    let mut value: u32 = 0;
    let mut significance = 1;

    for c in current_word.bytes().rev() {
        let digit = if c == '0' as u8 {
            0
        } else if c == '1' as u8 {
            1
        } else {
            return CompErr::err(pos, format!("Invalid octal literal: {}", current_word));
        };
        value += digit * significance;
        significance *= 2;

        if value > u16::MAX as u32 {
            return CompErr::err(pos, format!("Invalid int literal: {}", current_word));
        }
    }
    c.offset += current_word.len();
    Ok((pos, Token::IntValue(value as u16)))
}

fn get_tok_int_hex(c: &mut LexContext) -> TokenRes {
    let pos = c.pos();
    let current_word = id_slice(pos, &c.content, c.offset)?;

    let mut value: u32 = 0;
    let mut significance = 1;

    for c in current_word.bytes().rev() {
        let ch = (c as char).to_ascii_lowercase();
        let digit = if ch >= '0' && ch <= '9' {
            c as u32 - '0' as u32
        } else if ch >= 'a' && ch <= 'f' {
            10 + ch as u32 - 'a' as u32
        } else {
            return CompErr::err(pos, format!("Invalid hex literal: {}", current_word));
        };
        dbg!(digit, significance);
        value += digit * significance;
        significance *= 16;

        if value > u16::MAX as u32 {
            return CompErr::err(pos, format!("Hex literal is above 2^16: {}", current_word));
        }
    }
    c.offset += current_word.len();
    Ok((pos, Token::IntValue(value as u16)))
}

/// Seeks past horizontal whitespace
fn consume_hs(c: &mut LexContext) {
    while let Some(code) = c.content.get(c.offset) {
        match *code as char {
            ' ' | '\t' => c.offset += 1,
            ';' => consume_comment(c),
            _ => break,
        }
    }
}

fn consume_comment(c: &mut LexContext) {
    while let Some(code) = c.content.get(c.offset) {
        if *code as char == '\n' {
            break;
        }
        c.offset += 1;
    }
}

/// Extract an alphanumeric (and underscore) slice at the given offset.
/// Returns An empty slice if the offset is out of bounds,
/// or if there are no alphanumeric characters at that position
fn id_slice<'a>(pos: Pos, slice: &'a [u8], offset: usize) -> Result<&'a str, CompErr> {
    let len = id_len(slice, offset);

    if len == usize::MAX {
        return CompErr::err(pos, "Only ASCII is supported".to_string());
    }

    unsafe {
        Ok(std::str::from_utf8_unchecked(
            slice.get_unchecked(offset..offset + len),
        ))
    }
}

fn id_len(slice: &[u8], offset: usize) -> usize {
    // FIXME: Unsafe!
    let mut len = 0;
    unsafe {
        while offset + len < slice.len() {
            let c = *slice.get_unchecked(offset + len);

            if is_alphanum_underscore(c) {
                len += 1;
            } else if c > 0b01111111 {
                return usize::MAX;
            } else {
                break;
            }
        }
    }
    len
}

fn is_alphanum_underscore(c: u8) -> bool {
    (c >= 97 && c <= 122) | (c >= 65 && c <= 90) | (c >= 48 && c <= 57) | (c == 95)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn lex_single_from_str(s: &str) -> Result<Token, CompErr> {
        let content = s.to_owned();
        let mut c = LexContext::from_string(&content);
        pop_tok(&mut c).map(|pos_tok| pos_tok.1)
    }

    #[test]
    fn test_is_alphanum_underscore() {
        assert!(is_alphanum_underscore('z' as u8));
        assert!(is_alphanum_underscore('_' as u8));
        assert!(is_alphanum_underscore('5' as u8));
    }

    #[test]
    fn test_int_value() {
        assert_eq!(lex_single_from_str("%1010"), Ok(Token::IntValue(0b1010)));

        assert_eq!(lex_single_from_str("12340"), Ok(Token::IntValue(12340)));
        assert_eq!(lex_single_from_str("56789"), Ok(Token::IntValue(56789)));

        assert_eq!(lex_single_from_str("$1234"), Ok(Token::IntValue(0x1234)));
        assert_eq!(lex_single_from_str("$5678"), Ok(Token::IntValue(0x5678)));
        assert_eq!(lex_single_from_str("$90ab"), Ok(Token::IntValue(0x90ab)));
        assert_eq!(lex_single_from_str("$cdef"), Ok(Token::IntValue(0xcdef)));

        // Testing max size
        assert_eq!(
            lex_single_from_str("%1111111111111111"),
            Ok(Token::IntValue(65535))
        );
        assert_eq!(lex_single_from_str("65535"), Ok(Token::IntValue(65535)));
        assert_eq!(lex_single_from_str("$ffff"), Ok(Token::IntValue(65535)));

        // Testing over max size
        assert!(lex_single_from_str("%10000000000000000").is_err());
        assert!(lex_single_from_str("65536").is_err());
        assert!(lex_single_from_str("$10000").is_err());
    }

    #[test]
    fn test_newline() {
        assert_eq!(lex_single_from_str("\t   \n"), Ok(Token::Newline));
        assert_eq!(lex_single_from_str("\n"), Ok(Token::Newline));
    }

    #[test]
    fn test_comment() {
        assert_eq!(
            lex_single_from_str(" ; hello world  \n"),
            Ok(Token::Newline)
        );
        assert_eq!(lex_single_from_str(" ; hello world  "), Ok(Token::Eof));
    }
}
