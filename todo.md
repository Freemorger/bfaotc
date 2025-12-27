- more targets (win x64, darwin arm)
- optimize code: e.g., `+++` -> `add byte [rbx], 3` instead of
3 times `inc byte [rbx]`
