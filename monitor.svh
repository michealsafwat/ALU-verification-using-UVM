/****************************************************************************************************************************************
************************************************* Monitor CLASS *************************************************************************
****************************************************************************************************************************************/
class monitor extends uvm_monitor;
`uvm_component_utils (monitor)
virtual ALU_IF alu_if;
transaction trans;
transaction previous;
  uvm_analysis_port #(transaction) send_trans;
  event done;

function void build_phase(uvm_phase phase);
super.build_phase(phase);
 if (!uvm_config_db#(virtual ALU_IF)::get(this,"","ALU_if",alu_if))
 `uvm_error("MON","Unable")
   send_trans = new("WRITE", this);
  trans = transaction::type_id::create("trans");
  previous = transaction::type_id::create("previous");
endfunction

virtual task run_phase(uvm_phase phase);
  super.run_phase(phase);
  @(posedge alu_if.alu_clk);
 forever begin
   repeat(3) begin
       @(posedge alu_if.alu_clk);
   end 
     previous = trans.copy();
      mon_send_trans(trans);  
      ->done;
    end
endtask

virtual task mon_send_trans(transaction trans);     
  
  trans.alu_enable_a = alu_if.alu_enable_a;
      trans.alu_enable_b = alu_if.alu_enable_b;
      trans.alu_irq_clr = alu_if.alu_irq_clr;
      trans.alu_enable = alu_if.alu_enable;
      trans.alu_op_a = alu_if.alu_op_a;
      trans.alu_op_b = alu_if.alu_op_b;
      trans.alu_in_a = alu_if.alu_in_a;
      trans.alu_in_b = alu_if.alu_in_b;
      trans.rst_n = alu_if.rst_n;
  send_trans.write(previous.copy());
      @(posedge alu_if.alu_clk);
      trans.alu_out = alu_if.alu_out;
      trans.alu_irq = alu_if.alu_irq;
  trans.display("MON");
      send_trans.write(trans.copy());
endtask
  function new(string name = "monitor", uvm_component parent = null);
    super.new(name,parent);
    
  endfunction 

endclass 
