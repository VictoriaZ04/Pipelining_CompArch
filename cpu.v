`timescale 1ps/1ps

module main();

    initial begin
        $dumpfile("cpu.vcd");
        $dumpvars(0,main);
    end

    // initializing valid bits
    reg f1_v = 1;
    reg f2_v = 0;
    reg d_v  = 0;
    reg e1_v = 0;
    reg e2_v = 0;
    reg wb_v = 0;

    // initializing pc registers
    reg [15:0]f2_pc;
    reg [15:0]d_pc;
    reg [15:0]e1_pc;
    reg [15:0]e2_pc;
    reg [15:0]wb_pc;

    // --- stall bits ---
    
    // reg[x] = ---
    // reg[y] = mem(reg[x])
    wire ld_ld_hazard = (reg_wen && e1_insID == 7 && e1_ra == reg_waddr);

    // misaligned load/store  hazard
    wire mis_load = e1_v && (mem_raddr1[0:0] == 1 && (d_insID == 7 || d_insID == 8));
    wire mis_store_wire = (wb_v == 1 && e2_insID == 8 && e2_va[0:0] == 1);
    reg mis_store = 0;
    reg [15:0]wb_va = 0;
    reg [15:0]wb_vt = 0;

    // self modify hazard conditions
    wire self_modify_e2 = (wb_v && mem_wen && mem_waddr == e2_pc);
    wire self_modify_e1 = (wb_v && mem_wen && mem_waddr == e1_pc) || self_modify_e2;
    wire self_modify_d = (wb_v && mem_wen && mem_waddr == d_pc) || self_modify_e1;
    wire self_modify_f2 = (wb_v && mem_wen && mem_waddr == f2_pc) || self_modify_d;

    wire e2_stall = ld_ld_hazard || mis_store; 
    wire e1_stall = e2_stall;
    wire d_stall = e1_stall;
    wire f2_stall = d_stall;
    wire f1_stall = f2_stall || mis_load;
    reg stall; 


    // decode data
    reg misaligned_pc_primed = 0;
    reg [15:0]prev_word;
    wire [15:0]current_word;

    wire [15:0]instruction = (d_pc[0:0] && misaligned_pc_primed) ? {current_word[7:0], prev_word[15:8]} : current_word;
    reg [15:0]stall_instruction;

    wire [3:0]op = (stall) ? stall_instruction[15:12] : instruction[15:12];
    wire [3:0]ra = (stall) ? stall_instruction[11:8] : instruction[11:8];
    wire [3:0]rb = (stall) ? stall_instruction[7:4] : instruction[7:4];
    wire [3:0]rt = (stall) ? stall_instruction[3:0] : instruction[3:0];

    wire [3:0]insID = (op == 0) ? 0 :                  // sub
                      (op == 8) ? 1 :                  // movl
                      (op == 9) ? 2 :                  // movh
                      (op == 14 && rb == 0) ? 3 :      // jz
                      (op == 14 && rb == 1) ? 4 :      // jnz
                      (op == 14 && rb == 2) ? 5 :      // js
                      (op == 14 && rb == 3) ? 6 :      // jns
                      (op == 15 && rb == 0) ? 7 :      // ld
                      (op == 15 && rb == 1) ? 8 : 15;  // st

    reg [3:0]d_insID; // enumerated version of instruction type
    reg [3:0]d_ra;
    reg [3:0]d_rb;
    reg [3:0]d_rt;

    // execute 1 data
    reg [3:0]e1_insID;
    reg [15:0]e1_va;
    reg [15:0]e1_vtb;
    reg [3:0]e1_ra;
    reg [3:0]e1_rb;
    reg [3:0]e1_rt;

    // execute 2 data
    reg [3:0]e2_insID;
    reg [15:0]e2_va;
    reg [15:0]e2_vtb;
    reg [3:0]e2_ra;
    reg [3:0]e2_rb;
    reg [3:0]e2_rt;
    reg e2_st_ld_hazard;

    wire [15:0]calc_va = (reg_wen && reg_waddr == e1_ra) ? reg_wdata : e1_va; // check if using forwarded value
    wire [15:0]calc_vtb = (reg_wen && reg_waddr == ((e1_insID == 0) ? e1_rb : e1_rt)) ? reg_wdata : e1_vtb;

    reg [15:0]e2_result;
    reg e2_branch;
    
    // writeback data
    wire flush = (flushing || ! wb_v) ? 0 : e2_branch;
    reg flushing = 0;
    wire print = wb_v && 
                 e2_rt == 0 && 
                 (e2_insID == 0 || e2_insID == 1 || e2_insID == 2 || e2_insID == 7);

    // clock
    wire clk;
    clock c0(clk);

    reg halt = 0;

    counter ctr(halt,clk);

    // PC
    reg [15:0]pc = 16'h0000;


    // memory
    wire [15:0]mem_raddr0 = (mis_load) ? mem_raddr1 + 1: 
                            (f1_stall) ? f2_pc : pc;

    wire [15:0]mem_raddr1 = (ld_ld_hazard) ? reg_wdata : 
                            ((e2_v && d_ra == e1_rt && (e1_insID == 0 || e1_insID == 1 || e1_insID == 2 || e1_insID == 7)) || (wb_v && (d_ra == e2_rt) && (e2_insID == 0 || e2_insID == 1 || e2_insID == 2 || e2_insID == 7))) ? 0 :
                            ((d_ra == 0) ? 0 : reg_rdata0);
    wire [15:0]mem_rdata1;
    wire mem_wen = (e2_insID == 8 && wb_v) || mis_store;
    wire [15:0]mem_waddr = (mis_store) ? (wb_va + 1) : e2_va;
    wire [15:0]mem_wdata = (mis_store) ? wb_vt :
                           (e2_va[0:0] == 1) ? {e2_vtb[7:0], mem_rdata1[7:0]} : e2_vtb;

    mem mem(clk,
         mem_raddr0[15:1], current_word,
         mem_raddr1[15:1], mem_rdata1,
         mem_wen, mem_waddr[15:1], mem_wdata);


    // registers
    wire [3:0]reg_raddr0 = (d_stall) ? d_ra : ra;
    wire [15:0]reg_rdata0;
    wire [3:0]reg_raddr1 = (insID == 0) ? rb : rt;
    wire [15:0]reg_rdata1;
    wire reg_wen = (wb_v && e2_rt != 0 && 
                   (e2_insID == 0 || 
                    e2_insID == 1 || 
                    e2_insID == 2 || 
                    e2_insID == 7));

    wire [3:0]reg_waddr = e2_rt;
    wire [15:0]reg_wdata = (e2_insID != 7 || e2_st_ld_hazard) ? e2_result : 
                           (e2_insID == 7 && e2_va[0:0] == 1) ? {current_word[7:0], mem_rdata1[15:8]} : mem_rdata1;

    wire temp = (d_ra == 0);

    regs regs(clk,
        reg_raddr0, reg_rdata0,
        reg_raddr1, reg_rdata1,
        reg_wen, reg_waddr, reg_wdata);

    always @(posedge clk) begin

        // sets pc and checks for hazard condtions
        pc <= (e2_branch && wb_v) ? e2_result :
              (f1_stall) ? pc : 
              (self_modify_e2) ? e2_pc : // self modifying code
              (self_modify_e1) ? e1_pc : // self modifying code
              (self_modify_d) ? d_pc :   // self modifying code
              (self_modify_f2) ? f2_pc : // self modifying code
               pc + 2; 

        // propogating valid bits and checking hazards
        f2_v <= (f2_stall) ? f2_v :
                ((f1_v && !flush) && !self_modify_f2 && !mis_load);
        d_v  <= (d_stall) ? d_v :
                (f2_v && !flush) && !self_modify_f2;
        e1_v <= (e1_stall) ? e1_v :
                (d_v && !flush) && !self_modify_d && (!pc[0:0] || misaligned_pc_primed);
        e2_v <= (e2_stall) ? e2_v : 
                (e1_v && !flush) && !self_modify_e1;
        wb_v <= (e2_v && !flush) && 
                !((e2_insID == 15 && wb_v) && 
                !flushing) &&
                !self_modify_e2 &&
                !e2_stall;

        // propogating data
        f2_pc <= (f2_stall) ? f2_pc : pc;
        d_pc  <= (d_stall) ? d_pc : f2_pc;
        e1_pc <= (e1_stall) ? e1_pc : d_pc;
        e2_pc <= (e2_stall) ? e2_pc : e1_pc;
        wb_pc <= e2_pc;
        
        stall_instruction <= instruction;
        stall <= d_stall;

        prev_word <= current_word;
        misaligned_pc_primed <= (d_v);

        d_insID <= (d_stall) ? d_insID : insID;
        e1_insID <= (e1_stall) ? e1_insID : d_insID;
        e2_insID <= (e2_stall) ? e2_insID : e1_insID;

        e1_va <= (e1_stall) ? e1_va : 
                 ((reg_wen && reg_waddr == d_ra)) ? reg_wdata :  // forwarding data
                 ((d_ra == 0) ? 0 : reg_rdata0); // checking if reading r0

        e2_va <= (e2_stall) ? e2_va : 
                 ((reg_wen && reg_waddr == e1_ra)) ? reg_wdata : // forwarding data
                 ((e1_ra == 0) ? 0 : e1_va); // checking if reading r0

        e1_vtb <= (e1_stall) ? e1_vtb : 
                  (((d_insID == 0 && d_rb == 0) || (d_insID != 0 && d_rt == 0)) ? 0 : // checking is reading r0
                   (reg_wen && (reg_waddr == ((d_insID == 0) ? d_rb : d_rt))) ? reg_wdata : reg_rdata1); // forwarding data
        e2_vtb <= (e2_stall) ? e2_vtb : 
                  (reg_wen && (reg_waddr == ((e1_insID == 0) ? e1_rb : e1_rt))) ? reg_wdata : e1_vtb; // forwarding data

        d_ra <= (d_stall) ? d_ra : ra;
        e1_ra <= (e1_stall) ? e1_ra : d_ra;
        e2_ra <= (e2_stall) ? e2_ra : e1_ra;

        d_rb <= (d_stall) ? d_rb : rb;
        e1_rb <= (e1_stall) ? e1_rb : d_rb;
        e2_rb <= (e2_stall) ? e2_rb : e1_rb;
    
        d_rt <= (d_stall) ? d_rt : rt;
        e1_rt <= (e1_stall) ? e1_rt : d_rt;
        e2_rt <= (e2_stall) ? e2_rt : e1_rt;

        // Execute 2: Calculations

        // mem(x) = --
        // reg[y] = mem(x)
        e2_st_ld_hazard <= (mem_wen && mem_waddr == e1_va);

        // calculating results
        e2_result <= (e2_stall) ? e2_result : 
                     (e1_insID == 0) ? calc_va - calc_vtb:
                     (e1_insID == 1) ? {{8{e1_ra[3]}}, {e1_ra, e1_rb}} :
                     (e1_insID == 2) ? ((calc_vtb & 16'd255) | ({e1_ra, e1_rb} << 8)) :
                     (e1_insID == 3) ? calc_vtb :
                     (e1_insID == 4) ? calc_vtb :
                     (e1_insID == 5) ? calc_vtb :
                     (e1_insID == 6) ? calc_vtb :
                     (e1_insID == 7) ? ((mis_store_wire) ? e2_vtb : mem_wdata) :
                     (e1_insID == 8) ? calc_vtb : 0;
        
        // checking branch conditions
        e2_branch <= (e2_stall) ? e2_branch : 
                     (e1_insID == 3) ? calc_va == 0 :
                     (e1_insID == 4) ? calc_va != 0 :
                     (e1_insID == 5) ? $signed(calc_va) < 0 :
                     (e1_insID == 6) ? $signed(calc_va) >= 0 : 0;
        
        // Write Back
        
        mis_store <= mis_store_wire;
        wb_va <= e2_va;
        wb_vt <= {current_word[15:8], e2_vtb[15:8]};

        if (print) begin
            $write("%c", reg_wdata);
        end

        halt <= (e2_insID == 15 && wb_v) && !flushing;
        flushing <= flush;

    end


endmodule
