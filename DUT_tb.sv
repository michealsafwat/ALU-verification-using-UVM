

`include "uvm_macros.svh"
import uvm_pkg::*;
`timescale 1ns/1ps

/****************************************************************************************************************************************
************************************************* INTERFACE *************************************************************************
****************************************************************************************************************************************/

interface alu_if ();

  logic [3:0] a;
  logic [3:0] b;
  logic [1:0] op;
  logic       c;
  logic [3:0] out;
endinterface

interface clk_if ();

  logic tb_clk;

  initial tb_clk <= 0;

  always #10 tb_clk = ~tb_clk;

endinterface

/****************************************************************************************************************************************
************************************************* TRANSACTION CLASS(SEQUENCE ITEM) ******************************************************
****************************************************************************************************************************************/
class transaction extends uvm_sequence_item;

    rand  bit [3:0]   a;
    rand  bit [3:0]   b;
    rand  bit [1:0]   op; 
    bit           c;
    bit [3:0]   out;

  // this function used to print data
  function void print(string tag = "");
    $display("T=%0t %s a=0x%0h b=0x%0h op=0x%0h c=0x%0h out=0x%0h", $time, tag, a, b, op, c, out);
    
  endfunction

  // this function used to copy data
  function void copy(transaction tmp);
    this.a   = tmp.a;
    this.b   = tmp.b;
    this.op  = tmp.op;
    this.c   = tmp.c;
    this.out = tmp.out;
  endfunction



function new(string name = "TRANS");
        super.new(name);
    endfunction //new()
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(a,UVM_DEFAULT)
  `uvm_field_int(b,UVM_DEFAULT)
  `uvm_field_int(op,UVM_DEFAULT)
  `uvm_field_int(c,UVM_DEFAULT)
  `uvm_field_int(out,UVM_DEFAULT)
  `uvm_object_utils_end
endclass
/****************************************************************************************************************************************
************************************************* GENERATOR CLASS (SEQUENCE) ************************************************************
****************************************************************************************************************************************/
class generator extends uvm_sequence #(transaction);
`uvm_object_utils(generator)  // register in factory 
transaction item;
int loop = 8000;
int i = 0;


    function new(string name = "GEN");
        super.new(name);
        item= transaction::type_id::create("item");

    endfunction //new()

task body();
repeat(loop) begin
    start_item(item);
    $display("T=%0t [Generator] Loop:%0d/%0d create next item", $time, i + 1, loop);
    `uvm_info("GEN", "Data sent to driver", UVM_NONE);
        assert(item.randomize());
    finish_item(item);
    i = i+1;
    #20;
end
endtask:body
endclass //className extends superClass

/****************************************************************************************************************************************
************************************************* DRIVER CLASS *************************************************************************
****************************************************************************************************************************************/

class driver extends uvm_driver #(transaction);
`uvm_component_utils(driver)

transaction drv_item;
virtual alu_if ALU_if;
virtual clk_if clk;
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
drv_item = transaction::type_id::create("TRANS");
if(!uvm_config_db#(virtual alu_if)::get(this,"","ALU_if",ALU_if))
`uvm_info("DRV", "Unable to access Interface", UVM_NONE);
endfunction

virtual task run_phase(uvm_phase phase);
super.run_phase(phase);
forever begin
seq_item_port.get_next_item(drv_item);
drive_item(drv_item);
`uvm_info("DRV","Send data to DUT", UVM_NONE);
seq_item_port.item_done();
end
endtask

virtual task drive_item(transaction item);
ALU_if.a = item.a;
ALU_if.b = item.b;
ALU_if.op = item.op;
#20;
endtask

    function new(string name = "DRV", uvm_component parent);
        super.new(name,parent);
    endfunction //new()
endclass //driver extends superClass

/****************************************************************************************************************************************
************************************************* Monitor CLASS *************************************************************************
****************************************************************************************************************************************/
class monitor extends uvm_monitor ;
`uvm_component_utils(monitor)
uvm_analysis_port #(transaction) send_item;
transaction mon_item;
virtual alu_if ALU_if;
virtual clk_if clk;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
mon_item = transaction::type_id::create("TRANS");
if(!uvm_config_db#(virtual alu_if)::get(this,"","ALU_if",ALU_if))
`uvm_info("MON", "Unable to access Interface", UVM_NONE);
endfunction

virtual task run_phase(uvm_phase phase);
super.run_phase(phase);
forever begin
monitor_item(mon_item);



`uvm_info("MON","Send data to Scoreboard", UVM_NONE);
send_item.write(mon_item);
end
endtask

 virtual task monitor_item(transaction item);
#10;
item.a = ALU_if.a ;
item.b = ALU_if.b ;
item.op = ALU_if.op ;
#10;
item.c = ALU_if.c ;
item.out = ALU_if.out ;
endtask 

    function new(string name = "MON", uvm_component parent);
        super.new(name,parent);
        send_item = new("WRITE",this);
    endfunction //new()
endclass //driver extends superClass
/****************************************************************************************************************************************
************************************************* SCOREBOARD CLASS *************************************************************************
****************************************************************************************************************************************/
class scoreboard extends uvm_scoreboard;
`uvm_component_utils(scoreboard)
uvm_analysis_imp #(transaction,scoreboard) recv_item;


 typedef bit [10] inputs;
  int Passes = 0;
  int Fails = 0;
  bit unique_bug[inputs];
  inputs temp = 0;
  bit [4:0] ref_output;
  bit [4:0] alu_out;
  transaction ref_item = new;
 

virtual function void write(transaction data);
`uvm_info("SCO","Data rcvd from Monitor", UVM_NONE);
  ref_item.copy(data);
  case (ref_item.op)

        2'b00: begin
          temp = {data.a, data.b, data.op};
          ref_output = ref_item.a + ref_item.b;
          alu_out = {data.c, data.out};
          if (ref_output == alu_out) begin
           $display(
                "[%0t] Scoreboard Pass! Carry and Sum match, ref_output = 0x%0h alu_out = 0x%0h",
                $time, ref_output, alu_out);

          end else begin
            if (!unique_bug.exists(temp)) begin
              unique_bug[temp] = 1;
            end
             $error(
                "[%0t] Scoreboard Error! Carry and Sum mismatch, ref_output = 0x%0h alu_out = 0x%0h",
                $time, ref_output, alu_out);
          end


        end


        2'b01: begin
          temp = {data.a, data.b, data.op};
          ref_output = ref_item.a ^ ref_item.b;
          alu_out = {data.c, data.out};
          if (ref_output == alu_out) begin
             $display("[%0t] Scoreboard Pass! XOR match, ref_output = 0x%0h alu_out = 0x%0h", $time,
                     ref_output, alu_out);

          end else begin
            if (!unique_bug.exists(temp)) begin
              unique_bug[temp] = 1;
            end
             $error("[%0t] Scoreboard Error! XOR mismatch, ref_output = 0x%0h alu_out = 0x%0h",
                   $time, ref_output, alu_out);
          end


        end


        2'b10: begin
          temp = {data.a, data.b, data.op};
          ref_output = ref_item.a & ref_item.b;
          alu_out = {data.c, data.out};
          if (ref_output == alu_out) begin
            $display("[%0t] Scoreboard Pass! AND match, ref_output = 0x%0h alu_out = 0x%0h", $time,
                     ref_output, alu_out);
          end else begin
            if (!unique_bug.exists(temp)) begin
              unique_bug[temp] = 1;
            end
             $error("[%0t] Scoreboard Error! AND mismatch, ref_output = 0x%0h alu_out = 0x%0h",
                   $time, ref_output, alu_out);
          end


        end

        2'b11: begin
          temp = {data.a, data.b, data.op};
          ref_output = ref_item.a | ref_item.b;
          alu_out = {data.c, data.out};
          if (ref_output == alu_out) begin
             $display("[%0t] Scoreboard Pass! OR match, ref_output = 0x%0h alu_out = 0x%0h", $time,
                     ref_output, alu_out);

          end else begin
            if (!unique_bug.exists(temp)) begin
              unique_bug[temp] = 1;
            end

             $error("[%0t] Scoreboard Error! OR mismatch, ref_output = 0x%0h alu_out = 0x%0h",
                   $time, ref_output, alu_out);
          end


        end
      endcase
endfunction

    function new(string name = "SCB", uvm_component parent);
        super.new(name,parent);
        recv_item = new("READ",this);
            endfunction //new()
endclass //scoreboard extends superClass


/****************************************************************************************************************************************
************************************************* AGENT CLASS *************************************************************************
****************************************************************************************************************************************/
class agent extends uvm_agent;
`uvm_component_utils(agent)

driver d;
monitor m;
uvm_sequencer #(transaction) g;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
m = monitor::type_id::create("MON",this);
d = driver::type_id::create("DRV",this);
g = uvm_sequencer #(transaction)::type_id::create("GEN",this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
d.seq_item_port.connect(g.seq_item_export);
endfunction

    function new(string name= "AGENT", uvm_component parent);
        super.new(name,parent);
    endfunction //new()
endclass //agent extends superClass
/****************************************************************************************************************************************
************************************************* ENVIRONMENT CLASS *************************************************************************
****************************************************************************************************************************************/

class environment extends uvm_env;
`uvm_component_utils(environment)

function new(input string name = "ENV", uvm_component parent);
super.new(name,parent);
endfunction

scoreboard s;
agent a;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
a = agent::type_id::create("AGENT",this);
s = scoreboard::type_id::create("SCO",this);
endfunction


virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
a.m.send_item.connect(s.recv_item);
endfunction
endclass
/****************************************************************************************************************************************
************************************************* TEST CLASS *************************************************************************
****************************************************************************************************************************************/
class test extends uvm_test;
`uvm_component_utils(test)

function new(input string name = "TEST", uvm_component parent);
super.new(name,parent);
endfunction

generator gen;
environment e;

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
e = environment::type_id::create("ENV",this);
gen = generator::type_id::create("GEN",this);
endfunction

virtual task run_phase(uvm_phase phase);
phase.raise_objection(this);
gen.start(e.a.g);
$display("Unique bugs are equal to %0d", e.s.unique_bug.size());
phase.drop_objection(this);
endtask
endclass



/****************************************************************************************************************************************
************************************************* TB *************************************************************************
****************************************************************************************************************************************/
module DUT_tb;

  bit  tb_clk;
  test t;

  clk_if clk_interface ();
  alu_if ALU_if ();

  ALU dut0 (
      .a  (ALU_if.a),
      .b  (ALU_if.b),
      .op (ALU_if.op),
      .c  (ALU_if.c),
      .out(ALU_if.out)


  );

  initial begin
    $dumpfile("DUT_tb.vcd");
    $dumpvars;
 
 t =new("TEST",null);
      uvm_config_db#(virtual alu_if)::set(null, "*", "ALU_if", ALU_if);
    run_test();
    $finish;
  end


endmodule



