/****************************************************************************************************************************************
************************************************* SEQUENCE CLASS (SEQUENCE) ************************************************************
****************************************************************************************************************************************/

class base_sequence extends uvm_sequence #(transaction);
 `uvm_object_utils(base_sequence)
  transaction trans;
  int count = 10;
event done;
  function new(string name = "base_sequence");
    super.new (name);
  endfunction

  virtual task body();
    repeat (count) begin
      trans = transaction::type_id::create("trans");
     // `uvm_info("[SEQ]", "trans no.", UVM_LOW)
      start_item(trans);
      `uvm_info("[SEQ]", "Starting a transaction for the driver",UVM_LOW)
      assert (trans.randomize)
      else `uvm_error("[SEQ]","Transaction randomization failed")
     trans.display("SEQ");
      
      finish_item(trans);
      @(done);
      enables :
      assert ((trans.alu_enable_a & trans.alu_enable_b) != 1)
      else `uvm_error("[SEQ]", "Both enables for mode 'a' and mode 'b' are high!");

      illega_a_1 :
      assert (((trans.alu_enable_a && trans.alu_enable && (trans.alu_op_a == 2'b0)) && (trans.alu_in_b == 8'b0)) != 1)
      else `uvm_error("[SEQ]", "illegal value in mode 'a'!");

      illega_a_2 :
      assert (((trans.alu_enable_a && trans.alu_enable && (trans.alu_op_a == 2'b01)) && (trans.alu_in_b == 8'h03) && (trans.alu_in_a == 8'hff)) != 1)
      else `uvm_error("[SEQ]", "illegal value in mode 'a'!");

      illega_b_1 :
      assert (((trans.alu_enable_b && trans.alu_enable && (trans.alu_op_b == 2'b01)) && (trans.alu_in_b == 8'h03)) != 1)
      else `uvm_error("[SEQ]", "illegal value in mode 'b'!");

      illega_b_2 :
      assert (((trans.alu_enable_b && trans.alu_enable && (trans.alu_op_b == 2'b10)) && (trans.alu_in_a == 8'hf5)) != 1)
      else `uvm_error("[SEQ]", "illegal value in mode 'b'!");
       
    end
   
  endtask
endclass
