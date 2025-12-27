module main
import os
import cli

fn main() {
	mut app := cli.Command {
		name: 'bfaotc'
		description: 'Brainf*ck AOT compiler'
		execute: fn (cmd cli.Command) ! {
		}
		commands: [
			cli.Command {
				name: 'c'
				description: "Compile .bf file"
				execute: compile_handler,
			flags: [
				cli.Flag {
					flag: .string,
					name: 'target'
					abbrev: 't'
					description: 'target platform'
				},
			]
			}
		]
	};

	app.setup();
	app.parse(os.args);
}

fn compile_handler(cmd cli.Command) ! {
	if cmd.args.len == 0 {
		eprintln("Missing parameters; e.g. `bfaotc
c -target x86_64_linux input.bf");
		return
	}
	input_fname := cmd.args[0];
	target := match_target(cmd.flags.get_string('target') or { "x86_64_linux" }) or {
		return error('No such target')
	};

	toks := lex(input_fname)!;

	mut codegen := get_codegen(target);
	codegen.compile(toks)!;
	asm_fname := "${input_fname.replace(".bf", ".asm")}";
	codegen.write_asm(asm_fname)!;
	codegen.assemble("${input_fname.replace(".bf", "")}")!;

	$if prod {
		os.rm(asm_fname)!;
	}
}

