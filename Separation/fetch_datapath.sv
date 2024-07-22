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

module fetch_datapath(
    input wire clk,
    input wire rst_n,
    input wire type_fwd2if_s fwd2if,
    input wire type_csr2if_fb_s csr2if_fb,
    input wire type_exe2if_fb_s exe2if_fb,
    input wire if_stall,
    input wire is_jal,
    input wire type_icache2if_s icache2if,
    input wire irq_req_next,
    output logic [`XLEN-1:0] pc_next,
    output logic [`XLEN-1:0] pc_ff,
    output logic [`XLEN-1:0] instr_word,
    output logic [`XLEN-1:0] pc_plus_4
);

logic [`XLEN-1:0] instr;
logic [`XLEN-1:0] pc_plus_4_internal, pc_ff_internal, pc_next_internal; 
logic [`XLEN-1:0] jal_imm; 

// PC update state machine
always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        pc_ff_internal <= `PC_RESET;
    end else begin
        pc_ff_internal <= pc_next_internal;
    end
end

assign pc_plus_4_internal = pc_ff_internal + 32'd4;

always_comb begin
    pc_next_internal = pc_plus_4_internal;

    if (fwd2if.csr_new_pc_req) begin
        pc_next_internal = csr2if_fb.pc_new;
    end else if (fwd2if.wfi_req) begin
        pc_next_internal = csr2if_fb.pc_new;  
    end else if (fwd2if.exe_new_pc_req) begin
        pc_next_internal = exe2if_fb.pc_new;  
    end else if (if_stall) begin  
        pc_next_internal = pc_ff_internal;
    end else if (is_jal) begin
        pc_next_internal = pc_ff_internal + jal_imm;
    end
end

assign jal_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
assign instr = ((~icache2if.ack) | irq_req_next) ? `INSTR_NOP : icache2if.r_data;

assign instr_word = instr;
assign pc_plus_4 = pc_plus_4_internal;
assign pc_ff = pc_ff_internal;
assign pc_next = pc_next_internal;

endmodule : fetch_datapath
