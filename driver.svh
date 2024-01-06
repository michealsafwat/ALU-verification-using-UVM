/****************************************************************************************************************************************
************************************************* DRIVER CLASS (DRIVER) *************************************************************************
****************************************************************************************************************************************/

class driver extends uvm_driver #(transaction);
`uvm_component_utils(driver)
  transaction trans;
  virtual ALU_IF alu_if;

  function new(string name = "driver", uvm_component parent);
    super.new (name, parent);
  endfunction

function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db#(virtual ALU_IF)::get(this,"","ALU_if",alu_if))
  `uvm_error("DRV", "Unable to access Interface");
endfunction 

  
  virtual task drv_item(transaction trans);
      trans.display("DRV");
      @(posedge alu_if.alu_clk);
      alu_if.rst_n <= trans.rst_n;
      alu_if.alu_enable_a <= trans.alu_enable_a;
      alu_if.alu_enable_b <= trans.alu_enable_b;
      alu_if.alu_irq_clr <= trans.alu_irq_clr;
      alu_if.alu_enable <= trans.alu_enable;
      alu_if.alu_op_a <= trans.alu_op_a;
      alu_if.alu_op_b <= trans.alu_op_b;
      alu_if.alu_in_a <= trans.alu_in_a;
      alu_if.alu_in_b <= trans.alu_in_b;
    
  endtask
task reset();
    alu_if.rst_n <= 1'b0;
    alu_if.alu_enable_a <= 1'b0;
    alu_if.alu_enable_b <= 1'b0;
    alu_if.alu_irq_clr <= 1'b0;
    alu_if.alu_enable <= 1'b0;
    alu_if.alu_op_a <= 2'b0;
    alu_if.alu_op_b <= 2'b0;
    alu_if.alu_in_a <= 8'b0;
    alu_if.alu_in_b <= 8'b0;
    @(posedge alu_if.alu_clk);
    alu_if.rst_n <= 1'b1;
    @(posedge alu_if.alu_clk);
    `uvm_info("[DRV]", "reset done",UVM_LOW)
   
  endtask

  virtual task run_phase(uvm_phase phase);
    super.run_phase (phase);
    reset();
    forever begin
              

    `uvm_info("[DRV]","ALU Driver is requesting a transaction", UVM_LOW) 
    seq_item_port.get_next_item(trans);
      //`uvm_info("ALU_Driver_Reporting_Test","ALU Driver got the requested item", UVM_LOW) 
   drv_item(trans);
      `uvm_info("DRV","Data sent to DUT", UVM_LOW);
      @(posedge alu_if.alu_clk);
seq_item_port.item_done();
      repeat(2) begin
       @(posedge alu_if.alu_clk);
   end 
    end
  endtask
endclass
