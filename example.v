// `timescale 1ps/1ps

// module main;

//     initial begin
//         // Set up simulation for debugging
//         // Simulation details inside `initial` blocks
//         $dumpfile("cpu.vcd"); // "value change dump"
//         $dumpvars(0, main);
//     end

//     ////////////////////////////////////////////////////////////////////////////
//     //     Replicate P7 Starter Code Modules - Clock, Memory, Registers       //
//     ////////////////////////////////////////////////////////////////////////////

//     /*********
//      * Clock *
//      *********/
//     // Single bit, initially true
//     reg clock = 1;
//     always begin
//         // Every 500 time units, invert the clock
//         #500;
//         clock = ~clock; // = means blocking assignment
//     end

//     /**********
//      * Memory *
//      **********/
//     // 1024 words of 16 bits each
//     reg [15:0] mem [1023:0];
//     initial begin
//         // Ask to prepopulate values from file
//         // Starts at address 0, since the file starts with @0
//         // Inits the first 4 words (due to 4 lines in the hex file), leaves rest undefined
//         // Undefined values are tracked throughout simulation
//         $readmemh("mem.hex", mem);
//     end

//     /*************
//      * Registers *
//      *************/
//     // 16 words of 16 bits each
//     // HINT: very similar to how we did memory
//     reg [15:0] regs [15:0];
//     integer i;
//     initial begin
//         // p7 - don't have to do this - TCs cannot assume the initial state of registers
//         for (i = 0; i < 16; i++) regs[i] = i;
//     end
//     // Hack to see registers in gtkwave
//     // Just here since we don't have any printing to make sure the values updated correctly
//     wire [15:0] r0 = regs[0];
//     wire [15:0] r1 = regs[1];
//     wire [15:0] r2 = regs[2];
//     wire [15:0] r3 = regs[3];
//     wire [15:0] r4 = regs[4];
//     wire [15:0] r5 = regs[5];
//     wire [15:0] r6 = regs[6];

//     ////////////////////////////////////////////////////////////////////////////
//     //                     Implement Single Cycle Design                      //
//     ////////////////////////////////////////////////////////////////////////////

//     /******
//      * PC *
//      ******/
//     reg [15:0] pc = 0;

//     /*********
//      * Fetch *
//      *********/
//     // Fetch the instruction pointed to by the current PC
//     wire [15:0] ins = mem[pc[9:0]]; // read port
    

//     /**********
//      * Decode *
//      **********/
//     // Extract bits from the instruction
//     wire [3:0] opcode = ins[15:12];
//     wire [3:0] ra = ins[11:8];
//     wire [3:0] rb = ins[7:4];
//     wire [3:0] rt = ins[3:0];

//     // Decode the opcode into "one-hot encoding"
//     wire is_add = (opcode == 4'b0001);
//     // wire is_sub = (opcode == 4'b0010);
//     wire is_hlt = ~is_add; // & ~is_sub & ...

//     /************
//      * Operands *
//      ************/
//     // Read from registers to get the operands
//     wire [15:0] va = regs[ra];
//     wire [15:0] vb = regs[rb];

//     /***********
//      * Execute *
//      ***********/
//     // Perform the operation
//     // wire [15:0] result = va + vb;
//     wire [15:0] result = is_add ? va + vb :
//                         //  is_sub ? va - vb :
//                          16'bX;

//     // Determine what effects should occur (writing to regs, memory, jumping)
//     wire wen_regs = is_add; // | is_sub | ...
//     wire wen_mem = 0; // is_str
//     wire should_jump = 0; // Is the ins a jump, and is the condition met?
//     wire [15:0] target = should_jump ? result : pc + 1;

//     always @(posedge clock) begin
//         // Perform writeback
//         if (wen_regs) begin
//             regs[rt] <= result; // <= means non blocking assignment
//         end
//         if (wen_mem) begin
//             // Write to memory
//         end
//         pc <= target;
//     end

//     always @(posedge clock) begin
//         // Check if we should exit the simulation
//         // In p7 this is handled by the counter module
//         if (is_hlt) $finish();
//     end


// endmodule