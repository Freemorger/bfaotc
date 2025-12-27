# Simple [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck) AOT compiler written in V
Made for fun.
## Targets
Currently only targets linux x86_64, but other targets could be
implemented through interface `ICodegen` in future (or by you!).
## Build
Just build it with V compiler:
```sh
v .
```
You will also need fasm installed on your system in order to actually
run bfaotc, at least for linux x86_64
## Usage example:
```sh
./bfaotc c -target x86_64_linux example.bf
./example
```
