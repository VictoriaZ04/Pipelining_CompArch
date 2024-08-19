@0

// should print the entire alphabet in order

movl r3, #25
movl r4, #1
movl r5, #255
movl r1, #97
movl r2, #10
// loop at address 0xA

sub r0, r1, r0
sub r3, r3, r4
sub r1, r1, r5
jns r2, r3
halt
