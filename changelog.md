### Codegen optimizations
Some asm optimizations for x86_64-linux target: now `<`, `>`, `+`, `-`
sequences will be united into one assembly instruction, e.g.:
`+++` -> `add byte [rbx], 3` instead of 3 times `inc byte [rbx]`
