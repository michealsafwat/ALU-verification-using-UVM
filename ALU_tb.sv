`include "test_pkg.sv"
`include "uvm_macros.svh"
`timescale 1ns/1ps


/****************************************************************************************************************************************
************************************************* TB *************************************************************************
****************************************************************************************************************************************/
module DUT_tb;
  import uvm_pkg::*;
  import test_pkg::*;

  test t;

 ALU_IF alu_if ();
  ALU DUT (
      .alu_clk(alu_if.alu_clk),
      .rst_n(alu_if.rst_n),
      .alu_enable_a(alu_if.alu_enable_a),
      .alu_enable_b(alu_if.alu_enable_b),
      .alu_irq_clr(alu_if.alu_irq_clr),
      .alu_enable(alu_if.alu_enable),
      .alu_op_a(alu_if.alu_op_a),
      .alu_op_b(alu_if.alu_op_b),
      .alu_in_a(alu_if.alu_in_a),
      .alu_in_b(alu_if.alu_in_b),
      .alu_out(alu_if.alu_out),
      .alu_irq(alu_if.alu_irq)

  );

  initial begin
    alu_if.alu_clk <= 0;
  end

  always #16.665 alu_if.alu_clk <= ~alu_if.alu_clk;

covergroup enable;
option.per_instance = 1;
coverpoint DUT.alu_enable;

endgroup
  initial begin
    $dumpfile("DUT_tb.vcd");
    $dumpvars;
    t =new("TEST",null);
    uvm_config_db#(virtual ALU_IF)::set(null, "*", "ALU_if", alu_if);
    
    
    run_test();
  end
endmodule
