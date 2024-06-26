`timescale 1ns / 1ps
`include "a_ext_defs.svh"
module tb_amo;
logic clk=0;
logic rst_n;
type_lsu2amo_data_s lsu2amo_data_i;
type_lsu2amo_ctrl_s lsu2amo_ctrl_i;
type_amo2lsu_data_s amo2lsu_data_o;
type_amo2lsu_ctrl_s amo2lsu_ctrl_o;
amo uut (
    .rst_n(rst_n),
    .clk(clk),
    .lsu2amo_data_i(lsu2amo_data_i),
    .lsu2amo_ctrl_i(lsu2amo_ctrl_i),
    .amo2lsu_data_o(amo2lsu_data_o),
    .amo2lsu_ctrl_o(amo2lsu_ctrl_o)
);
always #5 clk = ~clk;
// Task for reset
task reset;
    begin
        rst_n = 0;
        #10;
        rst_n = 1;
    end
endtask
initial begin
    reset;

    // Test case: Load Reserved (LR)
    lsu2amo_ctrl_i.is_amo = 1;
    lsu2amo_ctrl_i.amo_ops = AMO_OPS_LR;
    lsu2amo_ctrl_i.ack = 1;
    lsu2amo_data_i.r_data = 32'h00000010;
    lsu2amo_data_i.rs2_operand = 32'hA5A5A5A5;
    lsu2amo_data_i.lsu_addr = 32'h1000;
    #20;

    // Test case: Store Conditional (SC) - should pass
    lsu2amo_ctrl_i.amo_ops = AMO_OPS_SC;
    lsu2amo_ctrl_i.ack = 1;
    #20;

    // Test case: Store Conditional (SC) - should fail
    uut.amo_buffer_data_ff = 32'hBADBEEF0;
    lsu2amo_data_i.rs2_operand = 32'h12345678;
    #20;

    // Test case: AMO SWAP
    lsu2amo_ctrl_i.amo_ops = AMO_OPS_SWAP;
    lsu2amo_data_i.rs2_operand = 32'h00000008;
    #20;

    // Test case: AMO ADD
    lsu2amo_ctrl_i.amo_ops = AMO_OPS_ADD;
    lsu2amo_data_i.rs2_operand = 32'h00000008;
    #20;

    // Test case: AMO AND
    lsu2amo_ctrl_i.amo_ops = AMO_OPS_AND;
    lsu2amo_data_i.rs2_operand = 32'h00000008;
    #20;

    // Test case: AMO Minimum
    lsu2amo_ctrl_i.amo_ops = AMO_OPS_MIN;
    lsu2amo_data_i.rs2_operand = 32'h80000008;
    #20;

    // Test case: AMO Maximum
    lsu2amo_ctrl_i.amo_ops = AMO_OPS_MAX;
    lsu2amo_data_i.rs2_operand = 32'h80000008;
    #20;

    // Test case: AMO Minimum (unsigned)
    lsu2amo_ctrl_i.amo_ops = AMO_OPS_MINU;
    lsu2amo_data_i.rs2_operand = 32'h80000008;
    #20;

    // Test case: AMO Maximum (unsigned)
    lsu2amo_ctrl_i.amo_ops = AMO_OPS_MAXU;
    lsu2amo_data_i.rs2_operand = 32'h80000008;
    #20;
    //No acknowledgement signal from LSU
    lsu2amo_ctrl_i.ack=0;
    lsu2amo_data_i.r_data = 32'h00000012;
    #20;
    $stop;
end

endmodule
