module main
import os

pub fn lex(fname string) ![]Tok {
	f_contents := os.read_file(fname)!.trim_space();
	mut res := []Tok;

	mut i := 0;
	for (i < f_contents.len) {
		ch := f_contents[i];
		match ch.ascii_str() {
			'>' {res << Tok.r_ang_br}
			'<' {res << Tok.l_ang_br}
			'+' {res << Tok.plus}
			'-' {res << Tok.minus}
			'.' {res << Tok.dot}
			',' {res << Tok.comma}
			'[' {res << Tok.l_br}
			']' {res << Tok.r_br}
			';' {
				mut j := i;
				for (j < f_contents.len) {
					newch := f_contents[j].ascii_str();
					if newch == '\n' {
						break
					}
					j += 1;
				}
				i = j;
			}
			'\n', ' ' {}
			else {eprintln("Unexpected char ${ch}")}
		}
		i += 1;
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
