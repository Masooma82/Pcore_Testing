`timescale 1ns / 1ps
`include "pcore_interface_defs.svh"
module tb_decode;

  // Parameters
  localparam RF_AWIDTH = 5;
  localparam XLEN = 32;

  // Inputs
  logic                             rst_n;
  logic                             clk;
  type_if2id_data_s                 if2id_data_i;
  type_if2id_ctrl_s                 if2id_ctrl_i;
  type_csr2id_fb_s                  csr2id_fb_i;
  type_wrb2id_fb_s                  wrb2id_fb_i;

  // Outputs
  type_id2exe_data_s                id2exe_data_o;
  type_id2exe_ctrl_s                id2exe_ctrl_o;

  // Instantiate the decode module
  decode uut (
    .rst_n(rst_n),
    .clk(clk),
    .if2id_data_i(if2id_data_i),
    .if2id_ctrl_i(if2id_ctrl_i),
    .id2exe_data_o(id2exe_data_o),
    .id2exe_ctrl_o(id2exe_ctrl_o),
    .csr2id_fb_i(csr2id_fb_i),
    .wrb2id_fb_i(wrb2id_fb_i)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz clock
  end

  // Test case
  initial begin
    // Reset
    rst_n = 0;
    if2id_data_i = '0;
    if2id_ctrl_i.exc_req = '0;
    if2id_ctrl_i.irq_req = '0;
    csr2id_fb_i.priv_mode = PRIV_MODE_M;
    if2id_data_i.exc_code = EXC_CODE_NO_EXCEPTION;
    if2id_data_i.instr = `INSTR_NOP;
    #10;
    rst_n = 1;

    // Test case 1: ADD instruction
    if2id_data_i.instr = 32'b0000000_00001_00010_000_00011_0110011; // ADD x3, x1, x2
    if2id_data_i.pc = 32'h00000000;
    if2id_data_i.pc_next = 32'h00000004;
    #10;


    // Test case 2: SUB instruction
    if2id_data_i.instr = 32'b0100000_00101_00010_000_00011_0110011; // SUB x3, x5, x2
    if2id_data_i.pc = 32'h00000004;
    if2id_data_i.pc_next = 32'h00000008;
    #10;

    // Test case 3: Load instruction
    if2id_data_i.instr = 32'h00002003; 
    if2id_data_i.pc = 32'h00000008;
    if2id_data_i.pc_next = 32'h0000000C;
    #10;

    // Test case 4: Store instruction
    if2id_data_i.instr = 32'h00002023; 
    if2id_data_i.pc = 32'h0000000C;
    if2id_data_i.pc_next = 32'h00000010;
    #10;

    // Test case 5: Branch instruction
    if2id_data_i.instr = 32'h00006063; 
    if2id_data_i.pc = 32'h00000010;
    if2id_data_i.pc_next = 32'h00000014;
    #10;

    // Test case 6: LUI instruction
    if2id_data_i.instr = 32'h00000037; 
    if2id_data_i.pc = 32'h00000014;
    if2id_data_i.pc_next = 32'h00000018;
    #10;

    // Test case 7: AUIPC instruction
    if2id_data_i.instr = 32'h00000017; 
    if2id_data_i.pc = 32'h00000018;
    if2id_data_i.pc_next = 32'h0000001C;
    #10;

    // Test case 8: JAL instruction
    if2id_data_i.instr = 32'h0000006F; 
    if2id_data_i.pc = 32'h0000001C;
    if2id_data_i.pc_next = 32'h00000020;
    #10;

    // Test case 9: JALR instruction
    if2id_data_i.instr = 32'h00000067;
    if2id_data_i.pc = 32'h00000020;
    if2id_data_i.pc_next = 32'h00000024;
    #10;

    // Test case 10: CSRRW
    if2id_data_i.instr = 32'b000000000000_00011_001_00001_1110011;
    if2id_data_i.pc = 32'h00000024;
    if2id_data_i.pc_next = 32'h00000028;
    #10;

    // Test case 11: ECALL
    if2id_data_i.instr = 32'b000000000000_00000_000_00000_1110011;
    if2id_data_i.pc = 32'h00000028;
    if2id_data_i.pc_next = 32'h00000030;
    #10;

    // Test case 12: EBREAK
    if2id_data_i.instr = 32'b000000000001_00000_000_00001_1110011;
    if2id_data_i.pc = 32'h00000030;
    if2id_data_i.pc_next = 32'h00000034;
    #10;

    // Test case 13: SRET
    if2id_data_i.instr = 32'b0001000_00010_00000_000_00000_1110011;
    if2id_data_i.pc = 32'h00000034;
    if2id_data_i.pc_next = 32'h00000038;
    #10;

    // Test case 14: MRET
    if2id_data_i.instr = 32'b0011000_00000_00000_000_00000_1110011;
    if2id_data_i.pc = 32'h00000038;
    if2id_data_i.pc_next = 32'h00000040;
    #10;

    // Test case 15: WFI
    if2id_data_i.instr = 32'b0001000_00101_00000_000_00000_1110011;
    if2id_data_i.pc = 32'h00000040;
    if2id_data_i.pc_next = 32'h00000044;
    #10;

    // Test case 16: illegal_instr
    if2id_data_i.instr = 32'b1111111_11111_11111_111_11111_1111111;
    if2id_data_i.pc = 32'h00000044;
    if2id_data_i.pc_next = 32'h00000048;
    #10;

     // Test case 17: AMO_LR
    if2id_data_i.instr = 32'b0001000_00000_00101_010_00010_0101111;
    if2id_data_i.pc = 32'h00000048;
    if2id_data_i.pc_next = 32'h00000050;
    #10; 

    // Test case 18: AMO_SC
    if2id_data_i.instr = 32'b0001100_00100_00101_010_00010_0101111;
    if2id_data_i.pc = 32'h00000050;
    if2id_data_i.pc_next = 32'h00000054;
    #10; 

        // Finish simulation
        $stop;
    end
    
endmodule
