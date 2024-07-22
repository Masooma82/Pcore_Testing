// Copyright 2023 University of Engineering and Technology Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: The fetch unit responsible for PC generation.
//
// Author: Muhammad Tahir, UET Lahore
// Date: 11.8.2022

`include "mmu_defs.svh"
`include "cache_defs.svh"
`include "pcore_csr_defs.svh"

module fetch_controller(
    input wire clk,
    input wire rst_n,
    input wire type_fwd2if_s fwd2if,
    input wire type_if2id_data_s if2id_data,
    input wire type_mmu2if_s mmu2if,
    input wire type_csr2if_fb_s csr2if_fb,
    input wire logic [`XLEN-1:0] pc_ff,
    input wire type_icache2if_s icache2if,
    output logic if_stall,
    output logic is_jal,
    output logic irq_req_next,
    output logic exc_req_next,
    output type_exc_code_e exc_code_next,
    output logic kill_req
);

logic pc_misaligned;
type_exc_code_e exc_code_next_internal, exc_code_ff;
logic exc_req_next_internal, exc_req_ff;
logic irq_req_next_internal, irq_req_ff;

// Evaluation for misaligned address
assign pc_misaligned = pc_ff[1] | pc_ff[0];

// Stall signal for IF stage
assign if_stall = fwd2if.if_stall | (~icache2if.ack) | irq_req_next_internal;
assign is_jal = if2id_data.instr[6:2] == OPCODE_JAL_INST;

// Instruction fetch related exceptions including address misaligned, instruction page fault 
// as well as instruction access fault
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        exc_req_ff  <= '0; 
        exc_code_ff <= EXC_CODE_NO_EXCEPTION;
    end else begin
        exc_req_ff  <= exc_req_next_internal;
        exc_code_ff <= exc_code_next_internal;
    end
end

always_comb begin
    exc_req_next_internal   = exc_req_ff;
    exc_code_next_internal  = exc_code_ff;
   
    if (fwd2if.csr_new_pc_req | fwd2if.exe_new_pc_req | fwd2if.wfi_req | (~fwd2if.if_stall & exc_req_ff)) begin    
        exc_req_next_internal  = 1'b0;
        exc_code_next_internal = EXC_CODE_NO_EXCEPTION;
    end else if (pc_misaligned) begin
        exc_req_next_internal  = 1'b1;
        exc_code_next_internal = EXC_CODE_INSTR_MISALIGN; 
    end else if (mmu2if.i_page_fault & ~exc_req_ff) begin
        exc_req_next_internal   = 1'b1;
        exc_code_next_internal  = EXC_CODE_INST_PAGE_FAULT; 
    end 

    // TODO : Deal with instruction access fault as well (EXC_CODE_INSTR_ACCESS_FAULT) for that 
    // purpose need a separate signal from MMU
end

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        irq_req_ff  <= '0; 
    end else begin
        irq_req_ff  <= irq_req_next_internal;
    end
end

always_comb begin
    irq_req_next_internal   = irq_req_ff;
   
    if (fwd2if.csr_new_pc_req | fwd2if.exe_new_pc_req | (~fwd2if.if_stall & irq_req_ff)) begin
        irq_req_next_internal  = 1'b0;
    end else if (csr2if_fb.irq_req & ~irq_req_ff) begin
        irq_req_next_internal   = 1'b1;
    end 
end

// Kill request to kill an ongoing request
assign kill_req = fwd2if.csr_new_pc_req | fwd2if.exe_new_pc_req;
assign irq_req_next = irq_req_next_internal;
assign exc_req_next = exc_req_next_internal;
assign exc_code_next = exc_code_next_internal;

endmodule : fetch_controller
