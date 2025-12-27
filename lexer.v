module main
import os

pub fn lex(fname string) ![]Tok {
	f_contents := os.read_file(fname)!;
	mut res := []Tok;

	for ch in f_contents.trim_space() {
		match ch.ascii_str() {
			'>' {res << Tok.r_ang_br}
			'<' {res << Tok.l_ang_br}
			'+' {res << Tok.plus}
			'-' {res << Tok.minus}
			'.' {res << Tok.dot}
			',' {res << Tok.comma}
			'[' {res << Tok.l_br}
			']' {res << Tok.r_br}
			else {eprintln("Unexpected char ${ch.ascii_str()}")}
		}
	}

	return res
}

pub enum Tok {
	r_ang_br // >
	l_ang_br
	plus
	minus
	dot
	comma
	l_br
	r_br
}
