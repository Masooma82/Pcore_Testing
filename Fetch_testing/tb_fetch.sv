`timescale 1ns / 1ps
`include "pcore_interface_defs.svh"
`include "pcore_config_defs.svh"
`include "mmu_defs.svh"
`include "cache_defs.svh"

module tb_fetch;

    // Inputs
    reg clk;
    reg rst_n;
    type_icache2if_s  icache2if_i;
    type_mmu2if_s  mmu2if_i;
    type_exe2if_fb_s exe2if_fb_i;
    type_csr2if_fb_s csr2if_fb_i;
    type_fwd2if_s fwd2if_i;

    // Outputs
    type_if2icache_s if2icache_o;
    type_if2mmu_s if2mmu_o;
    type_if2id_data_s if2id_data_o;
    type_if2id_ctrl_s if2id_ctrl_o;

    // Instantiate the Unit Under Test (UUT)
    fetch uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .if2icache_o(if2icache_o), 
        .icache2if_i(icache2if_i), 
        .if2mmu_o(if2mmu_o), 
        .mmu2if_i(mmu2if_i), 
        .if2id_data_o(if2id_data_o), 
        .if2id_ctrl_o(if2id_ctrl_o), 
        .exe2if_fb_i(exe2if_fb_i), 
        .csr2if_fb_i(csr2if_fb_i), 
        .fwd2if_i(fwd2if_i)
    );

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;

        // Wait for global reset to finish
        #100;
        
        
        
        // Stimulate inputs
        #10;
        icache2if_i.r_data = `INSTR_NOP;
        #10;
        // Release reset
        rst_n = 1;
        // Test case 1: Normal operation
        #10;
        fwd2if_i = 1; // simulate stall
        #10;
        fwd2if_i = 0; // remove stall
        #10;
        
        // Test case 2: Address misaligned exception
        uut.pc_ff = 32'h00000003; // Misaligned address
        #10;
        
        // Test case 3: Page fault
        // Assuming a page fault signal is set in the real MMU implementation
        mmu2if_i.i_page_fault = 1;
        #10;
        
        // Test case 4: Interrupt request
        // Assuming an IRQ signal is set in the real CSR implementation
        csr2if_fb_i.irq_req = 1;
        #10;
        
        // Test case 5: JAL instruction
        icache2if_i.r_data[6:2] = OPCODE_JAL_INST; // JAL instruction opcode
        #10;
        
        // Test case 6: New PC request from CSR
        csr2if_fb_i.pc_new = 32'h00000020; // New PC
        fwd2if_i.csr_new_pc_req = 1; // Set new PC request
        #10;
        fwd2if_i.csr_new_pc_req = 0; // Clear new PC request
        #10;
        
        // Test case 7: New PC request from EXE
        exe2if_fb_i.pc_new = 32'h00000040; // New PC
        fwd2if_i.exe_new_pc_req = 1; // Set new PC request
        #10;
        fwd2if_i.exe_new_pc_req = 0; // Clear new PC request
        #10;
        
        // Finish simulation
        $finish;
    end
    
    // Clock generation
    always #5 clk = ~clk;
    
endmodule
