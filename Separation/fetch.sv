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

module fetch (
    input   logic                                   rst_n,           // reset
    input   logic                                   clk,             // clock

    // IF <---> ICACHE MEM interface
    output type_if2icache_s                         if2icache_o,     // Instruction cache memory request
    input   wire  type_icache2if_s                  icache2if_i,     // Instruction cache memory response

    // IF <---> MMU interface
    output type_if2mmu_s                            if2mmu_o,        // Instruction memory request
    input   wire type_mmu2if_s                      mmu2if_i,        // Instruction memory response

    // IF <---> ID interface
    output type_if2id_data_s                        if2id_data_o,
    output type_if2id_ctrl_s                        if2id_ctrl_o, 

    // EXE <---> Fetch feedback interface
    input   wire   type_exe2if_fb_s                  exe2if_fb_i,

    // CSR <---> Fetch feedback interface
    input   wire   type_csr2if_fb_s                  csr2if_fb_i,
    
    // Forward <---> Fetch interface
    input   wire    type_fwd2if_s                    fwd2if_i
);


// Local signals       
type_icache2if_s                     icache2if;
type_if2mmu_s                        if2mmu;
type_mmu2if_s                        mmu2if;

type_if2id_data_s                    if2id_data;
type_if2id_ctrl_s                    if2id_ctrl;

type_exe2if_fb_s                     exe2if_fb;
type_csr2if_fb_s                     csr2if_fb;

type_fwd2if_s                        fwd2if;

// Exception related signals
type_exc_code_e                      exc_code_next;
logic                                exc_req_next;
logic                                irq_req_next;
logic                                kill_req;

// Imem address generation
logic [`XLEN-1:0]                    pc_ff, pc_plus_4; // Current value of program counter (PC)
logic [`XLEN-1:0]                    pc_next;           // Updated value of PC
logic [`XLEN-1:0]                    instr_word;
logic                                if_stall;

////////////////////////////////////////////////////////////////
logic [`XLEN-1:0]                    pc_new_jal;         
logic                                is_jal;

assign icache2if = icache2if_i;
assign mmu2if    = mmu2if_i;

assign exe2if_fb = exe2if_fb_i;
assign csr2if_fb = csr2if_fb_i;
assign fwd2if    = fwd2if_i;

fetch_datapath fd (
    .clk(clk),
    .rst_n(rst_n),
    .fwd2if(fwd2if),
    .csr2if_fb(csr2if_fb),
    .exe2if_fb(exe2if_fb),
    .if_stall(if_stall),
    .is_jal(is_jal),
    .icache2if(icache2if),
    .irq_req_next(irq_req_next),
    .pc_next(pc_next),
    .pc_ff(pc_ff),
    .instr_word(instr_word),
    .pc_plus_4(pc_plus_4)
);

fetch_controller fc (
    .clk(clk),
    .rst_n(rst_n),
    .fwd2if(fwd2if),
    .if2id_data(if2id_data),
    .mmu2if(mmu2if),
    .csr2if_fb(csr2if_fb),
    .pc_ff(pc_ff),
    .icache2if(icache2if),
    .if_stall(if_stall),
    .is_jal(is_jal),
    .irq_req_next(irq_req_next),
    .exc_req_next(exc_req_next),
    .exc_code_next(exc_code_next),
    .kill_req(kill_req)  
);

// Update the outputs to MMU and Imem modules
assign if2mmu.i_vaddr  = pc_next;
assign if2mmu.i_req    = `IMEM_INST_REQ; 
assign if2mmu.i_kill   = kill_req;

assign if2icache_o.addr     = mmu2if.i_paddr[`XLEN-1:0]; // pc_next; 
assign if2icache_o.req      = mmu2if.i_hit;              // `IMEM_INST_REQ;
assign if2icache_o.req_kill = kill_req;
assign if2icache_o.icache_flush = csr2if_fb.icache_flush;

// Update the outputs to ID stage
assign if2id_data.instr         = instr_word;
assign if2id_data.pc            = pc_ff;
assign if2id_data.pc_next       = is_jal ? pc_plus_4 : pc_next;
assign if2id_data.instr_flushed = 1'b0;

assign if2id_data.exc_code      = exc_code_next;
assign if2id_ctrl.exc_req       = exc_req_next;
assign if2id_ctrl.irq_req       = irq_req_next;

// Connect outputs to module ports
assign if2id_data_o = if2id_data;
assign if2id_ctrl_o = if2id_ctrl;
assign if2mmu_o     = if2mmu;

endmodule : fetch
