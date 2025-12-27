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
		"x86_64_linux" {return Targets.x86_64_linux}
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
}

pub fn new_cgen_lin64() &Cgen_linux64 {
	return &Cgen_linux64 {
		asm_fname: ""
		buf: []string{}
	}
}

pub fn (mut c Cgen_linux64) compile(toks []Tok) ! {
	c.prepare_lin64_asm();

	for t in toks {
		match t {
			.r_ang_br {
				c.buf << "inc rbx"
			}
			.l_ang_br {
				c.buf << "dec rbx"
			}
			.plus {
				c.buf << "inc byte [rbx]"
			}
			.minus {
				c.buf << "dec byte [rbx]"
			}
			.dot {
				c.buf << "mov rax, 1" // sys_write
				c.buf << "mov rdi, 1" // stdout
				c.buf << "lea rsi, [rbx]"
				c.buf << "mov rdx, 1" // 1 byte
				c.buf << "syscall"

				c.buf << "mov rax, 36" // sys_sync
				c.buf << "syscall"
			}
			else {
				eprintln("unimplemented.. yet")
			}
		}
	}

	c.finalize_lin64_asm();
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
