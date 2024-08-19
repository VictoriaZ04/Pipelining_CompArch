// `timescale 1ps/1ps

// module main();

//     initial begin
//         $dumpfile("cpu.vcd");
//         $dumpvars(0,main);
//     end

//     reg flush = 0;
//     wire flushing_w = (flush) ? 0 : (wb_v && e2_branch);

//     // fetch 2 values

//     reg [15:0]f2_pc;

//     // decode values

//     wire [3:0]op = ins[15:12];
//     wire [3:0]rb = ins[7:4];

//     reg [15:0]d_pc;
//     reg d_isLd_reg;
    

//     // execute 1 values

//     reg [15:0]e1_pc;
//     reg [1:0]e1_wmode;
//     reg [3:0]e1_rt;
//     reg [15:0]e1_res;
//     reg [15:0]e1_va;
//     reg e1_isLd_reg;
//     reg e1_branch;

//     // execute 2 values

//     reg [15:0]e2_pc;
//     reg [1:0]e2_wmode;
//     reg [3:0]e2_rt;
//     reg [15:0]e2_res;
//     reg [15:0]e2_va;
//     reg e2_branch;

//     // write back values

//     reg [15:0]wb_pc;
//     reg [1:0]wb_wmode;
//     reg [3:0]wb_rt;
//     reg [15:0]wb_res;
//     reg [15:0]wb_va;
//     reg wb_branch = 0;

//     // clock
//     wire clk;
//     clock c0(clk);

//     reg halt = 0;

//     counter ctr(halt,clk);

//     // PC
//     // wire branch = ((isJz && wb_va == 0) || 
//     //               (isJns && wb_va != 0) ||
//     //               (isJs && wb_va < 0) ||
//     //               (isJns && wb_va >=0)) ? 1 : 0; // FIX ME
//     wire branch = 0;
//     wire [15:0]branch_addr = wb_res;
//     reg [15:0]pc = 16'h0000;
//     wire [15:0]ins;

//     // initializing valid shift registers
//     reg f1_v = 1;
//     reg f2_v = 0;
//     reg d_v  = 0;
//     reg e1_v = 0;
//     reg e2_v = 0;
//     reg wb_v = 0;

//     // read from memory
//     wire [15:0]mem_out1;
//     wire wen = (wb_wmode == 3 && wb_v);
//     // wire [15:0]mem_write_addr;
//     // wire [15:0]mem_write_data = wb_res;

//     // memory
//     // mem(input clk, input raddr0_, output rdata0_, input raddr1_, output rdata1_, input wen, input waddr, input wdata);
//     mem mem(clk, 
//             (branch && wb_v) ? branch_addr[15:1] : pc[15:1], ins, 
//             va[15:1], mem_out1, 
//             wen, 
//             wb_va[15:1], wb_res);

//     wire [3:0]ra = ins[11:8];
//     wire [15:0]va;
//     wire [3:0]rt = ins[3:0];
//     wire [15:0]vt;
//     wire regs_wen = (wb_wmode == 1 && wb_rt != 0 && wb_v);
//     wire print = wb_wmode == 1 && wb_rt == 0 && wb_v;

//     // registers
//     regs regs(clk, 
//               ra, va, 
//               (op == 0) ? rb : rt, vt, 
//               regs_wen, wb_rt, wb_res);

//     // Operations:
//     wire [15:0]sub = va-vt;
//     reg [15:0]temp;


//     // ** initializing wires and registers **//
    
//     reg isSub;
//     reg isMovl;
//     reg isMovh;
//     reg isJz; 
//     reg isJnz; 
//     reg isJs; 
//     reg isJns; 
//     reg isLd; 
//     reg isSt; 

//     reg [3:0]a;
//     reg [3:0]b;
//     reg [3:0]t;

//     reg invalid;
    

//     always @(posedge clk) begin
//         temp = 5;

//         pc   <= (wb_branch) ? wb_res : pc + 2;

//         f2_v <= (f1_v && !flushing_w);
//         d_v  <= (f2_v && !flushing_w);
//         e1_v <= (d_v && !flushing_w);
//         e2_v <= (e1_v && !flushing_w);
//         // wb_v <= e2_v;
//         wb_v <= (e2_v && !flushing_w);

//         // propogate pc
//         f2_pc <= pc;
//         d_pc <= f2_pc;
//         e1_pc <= d_pc;
//         e2_pc <= e1_pc;
//         wb_pc <= e2_pc;
        
//         // Decode OP Code

//         isSub  <= (op == 0) ? 1 : 0;
//         isMovl <= (op == 8) ? 1 : 0;
//         isMovh <= (op == 9) ? 1 : 0;
//         isJz   <= (op == 14 && rb == 0) ? 1 : 0; 
//         isJnz  <= (op == 14 && rb == 1) ? 1 : 0; 
//         isJs   <= (op == 14 && rb == 2) ? 1 : 0; 
//         isJns  <= (op == 14 && rb == 3) ? 1 : 0; 
//         isLd   <= (op == 15 && rb == 0) ? 1 : 0; 
//         isSt   <= (op == 15 && rb == 1) ? 1 : 0; 

//         a <= ra;
//         b <= rb;
//         t <= rt;

//         d_isLd_reg <= isLd;


//         invalid <= (isSub || isMovl || isMovh || isJz || isJnz || isJs || isJns || isLd || isSt) ? 0 : 1;

//         halt <= (invalid && e1_v);

//         // Execute 1
//         e1_wmode <= (isSt) ? 3 : (isJz || isJnz || isJs || isJns) ? 2 : 1; // 3 = write to mem ; 2 = jump; 1 = write to reg
//         e1_rt <= t;
//         e1_res <= (isSub) ? ((a == 0) ? 0 :va)-((b == 0) ? 0 :vt) :
//                   (isMovl) ? {{8{a[3]}}, {a, b}} :
//                   (isMovh) ? ((((t == 0) ? 0 : vt) & 16'd255) | ({a,b} << 8)) :
//                   (isJz) ? ((t == 0) ? 0 : vt) :
//                   (isJnz) ? ((t == 0) ? 0 : vt) :
//                   (isJs) ? ((t == 0) ? 0 : vt) :
//                   (isJns) ? ((t == 0) ? 0 : vt) :
//                   (isLd) ? 0 :
//                   (isSt) ? ((t == 0) ? 0 : vt) : 0;
//         e1_va <= va;
//         e1_isLd_reg <= d_isLd_reg;
//         e1_branch <= (isJz) ? ((a == 0) ? 0 : va) == 0 :
//                      (isJnz) ? ((a == 0) ? 0 : va) != 0 :
//                      (isJs) ? $signed(((a == 0) ? 0 : va)) < 0 :
//                      (isJns) ? $signed(((a == 0) ? 0 : va)) >= 0 : 0;

//         if (print) begin
//             $write("%c", wb_res);
//         end

//         // Execute 2 : does nothing
//         e2_wmode <= e1_wmode;
//         e2_rt <= e1_rt;
//         e2_res <= e1_res;
//         e2_va <= e1_va;
//         e2_branch <= e1_branch;

//         // WB
//         wb_wmode <= e2_wmode;
//         wb_rt <= e2_rt;
//         wb_res <= (e1_isLd_reg) ? mem_out1 : e2_res;
//         wb_va <= e2_va;
//         wb_branch <= e2_branch && wb_v;

//         flush <= (flush) ? 0 : (wb_v && e2_branch);


//     end


// endmodule
