module main
import os

pub interface ICodegen {
	assemble(output string) !
mut:
	write_asm(output string) !
	compile(toks []Tok) !
}

/// Available target platforms
/// TODO: x86_64_windows
pub enum Targets {
	x86_64_linux
}

pub fn match_target(name string) ?Targets {
	match name.to_lower().trim_space() {
		"x86_64_linux", "x86_64-linux" {return Targets.x86_64_linux}
		else {
			eprintln("Unknown target ${name.to_lower()}");
			return none
		}
	}
}

pub fn get_codegen(tgt Targets) &ICodegen {
	match tgt {
		.x86_64_linux {
			return new_cgen_lin64()
		}
	}
}

pub struct Cgen_linux64 {
mut:
	buf	[]string
	asm_fname string
	loops_stack []int
	ls_ctr	int
}

pub fn new_cgen_lin64() &Cgen_linux64 {
	return &Cgen_linux64 {
		asm_fname: ""
		buf: []string{}
		loops_stack: []int{}
		ls_ctr : 0
	}
}

pub fn (mut c Cgen_linux64) compile(toks []Tok) ! {
	c.prepare_lin64_asm();

	mut i := 0;
	for (i < toks.len) {
		t := toks[i];
		match t {
			.r_ang_br {
				ctr := count_streak(toks, t, i);
				if ctr > 1 {
					i += (ctr - 1);
					c.buf << "add rbx, ${ctr}"
				} else {
					c.buf << "inc rbx"
				}
			}
			.l_ang_br {
				ctr := count_streak(toks, t, i);
				if ctr > 1 {
					i += (ctr - 1);
					c.buf << "sub rbx, ${ctr}"
				} else {
					c.buf << "dec rbx"
				}
			}
			.plus {
				ctr := count_streak(toks, t, i);
				if ctr > 1 {
					i += (ctr - 1);
					c.buf << "add byte [rbx], ${ctr}"
				} else {
					c.buf << "inc byte [rbx]"
				}
			}
			.minus {
				ctr := count_streak(toks, t, i);
				if ctr > 1 {
					i += (ctr - 1);
					c.buf << "sub byte [rbx], ${ctr}"
				} else {
					c.buf << "dec byte [rbx]"
				}
			}
			.dot {
				c.buf << "mov rax, 1" // sys_write
				c.buf << "mov rdi, 1" // stdout
				c.buf << "lea rsi, [rbx]"
				c.buf << "mov rdx, 1" // 1 byte
				c.buf << "syscall"
			}
			.comma {
				c.buf << "xor rax, rax" // 0 - sys_read
				c.buf << "xor rdi, rdi" // 0 - stdin
				c.buf << "lea rsi, [rbx]"
				c.buf << "mov rdx, 1" // read 1 byte
				c.buf << "syscall"
			}
			.l_br {
				c.buf << "loop_${c.ls_ctr}:"
				c.buf << "mov al, byte [rbx]"
				c.buf << "test al, al"
				c.buf << "jz loop_${c.ls_ctr}_exit"

				c.loops_stack << c.ls_ctr
				c.ls_ctr += 1;
			}
			.r_br {
				if c.loops_stack.len == 0 {
					panic("${t}: attempting to close loop, but it\
						never started");
				}
				num := c.loops_stack.pop();
				c.buf << "jmp loop_${num}"
				c.buf << "loop_${num}_exit:"
			}
		}
		i += 1;
	}

	c.finalize_lin64_asm();
}

fn count_streak(toks []Tok, want Tok, cur int) int {
	mut ctr := 1; // streak
	for j in (cur + 1)..toks.len {
		if toks[j] == want {
			ctr += 1;
		} else {
			break
		}
	}
	return ctr
}

pub fn (mut c Cgen_linux64) write_asm(output string) ! {
	os.write_lines(output, c.buf)!;
	c.asm_fname = output;
}

pub fn (c Cgen_linux64) assemble(output string) ! {
	os.system("fasm ${c.asm_fname}");
}


fn (mut c Cgen_linux64) prepare_lin64_asm() {

	c.buf << "format ELF64 executable 3";
	c.buf << "entry start";

	// bss 30k zeroed bytes
	c.buf << "segment readable writable";
	c.buf << "tape rb 30000";
	c.buf << "db 0";

	c.buf << "segment readable executable";
	c.buf << "start:";
	c.buf << "lea rbx, [tape]";
}

fn (mut c Cgen_linux64) finalize_lin64_asm() {
	// exiting program normally
	c.buf << "mov rax, 60";
	c.buf << "xor rdi, rdi";
	c.buf << "syscall";
}
