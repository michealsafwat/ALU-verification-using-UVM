/****************************************************************************************************************************************
************************************************* SCOREBOARD CLASS (SCOREBOARD)**********************************************************
****************************************************************************************************************************************/

  bit [7:0] excpected_out;
bit [9:0] event_trigger_a[4] = '{10'h0FF, 10'h100, 10'h2F8, 10'h383};
bit [9:0] event_trigger_b[4] = '{10'h0F1, 10'h1F4, 10'h2F5, 10'h3FF};

bit trigger;
  
  


class  scoreboard extends uvm_scoreboard;
`uvm_component_utils(scoreboard)
uvm_analysis_imp #(transaction,scoreboard) recv_trans;
transaction trans, prev_trans; 
   transaction item_q[$];
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    recv_trans = new("READ",this);
    
  endfunction
  
  virtual function void write(transaction recv_trans);
   // `uvm_info("SCO","Data recieved from Monitor", UVM_LOW);
    item_q.push_back(recv_trans);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
  super.run_phase(phase);
 forever begin
   wait(item_q.size == 2);
     prev_trans = item_q.pop_front();   
     trans = item_q.pop_front();   
 $display("[SCB]: RESET = %0d\n", trans.rst_n);

      if (trans.rst_n == 1'b1) begin
        if (trans.alu_enable == 1'b1) begin
          if ((trans.alu_enable_a | trans.alu_enable_b) == 1'b0) begin
            `uvm_info("[SCB]" , "The two modes are off so the outputs should remain the same\n",UVM_LOW);
            if (prev_trans.alu_out != trans.alu_out) begin

              `uvm_info("[SCB]" , "Output changed while the two modes are off \n",UVM_LOW);
              $display(
                  "[SCB]: Previous output is alu_out = %0d, \n Current output is alu_out = %0d\n ",
                  prev_trans.alu_out, trans.alu_out);
              `uvm_info("[SCB]" , "MISMATCH\n", UVM_LOW);
              $display(
                  "****************************************************************************************************");
            end else if ((prev_trans.alu_irq_clr == 1'b0) && (trans.alu_irq == prev_trans.alu_irq) ) begin


              $display(
                  "[SCB]: Previous outputs are alu_out = %0d, alu_irq = %0d\n Current outputs are alu_out = %0d, alu_irq = %0d\n  ",
                  prev_trans.alu_out, prev_trans.alu_irq, trans.alu_out, trans.alu_irq);
`uvm_info("[SCB]" ,"PASSED\n",UVM_LOW);
              $display(
                  "****************************************************************************************************");


            end
        else if ((prev_trans.alu_irq_clr == 1'b0) && (trans.alu_irq != prev_trans.alu_irq) ) begin


              $display(
                  "[SCB]: Previous output is alu_irq = %0d\n Current output is alu_irq = %0d\n  ",
                  prev_trans.alu_irq, trans.alu_irq);
              `uvm_info("[SCB]" , "MISMATCH\n", UVM_LOW);

              $display(
                  "****************************************************************************************************");


            end else if (((prev_trans.alu_irq_clr == 1'b1) && (trans.alu_irq == 1'b0))) begin

              $display(
                  "[SCB]: Previous outputs are alu_out = %0d, alu_irq = %0d\n, alu_irq_clr is high so alu_irq should be low, Current outputs are alu_out = %0d, alu_irq = %0d\n  ",
                  prev_trans.alu_out, prev_trans.alu_irq, trans.alu_out, trans.alu_irq);
`uvm_info("[SCB]" ,"PASSED\n",UVM_LOW);
              $display(
                  "****************************************************************************************************");

            end else if (((prev_trans.alu_irq_clr == 1'b1) && (trans.alu_irq == 1'b1))) begin

              $display(
                  "[SCB]: Previous output is alu_irq = %0d, current alu_irq should be low, Current output is alu_irq = %0d\n  ",
                  prev_trans.alu_irq, trans.alu_irq);
              `uvm_info("[SCB]" , "MISMATCH\n", UVM_LOW);

              $display(
                  "****************************************************************************************************");

            end
          end
          /////////////////////////////////////////////////////////////

    if ((trans.alu_enable_a == 1'b1) && (trans.alu_enable_b == 1'b0)) begin
      case (trans.alu_op_a)
        2'b00: excpected_out = trans.alu_in_a & trans.alu_in_b;
        2'b01: excpected_out = ~(trans.alu_in_a & trans.alu_in_b);
        2'b10: excpected_out = trans.alu_in_a | trans.alu_in_b;
        2'b11: excpected_out = trans.alu_in_a ^ trans.alu_in_b;
      endcase
      $display("[SCB]: Operating in mode 'a', alu_op_a = %0d, alu_in_a = %0d, alu_in_b = %0d\n ",
               trans.alu_op_a, trans.alu_in_a, trans.alu_in_b);
      if (excpected_out == trans.alu_out) begin
        foreach (event_trigger_a[i]) begin
          if (event_trigger_a[i] == {trans.alu_op_a, excpected_out}) begin
            trigger = 1'b1;
            break;
          end
        end
      end else begin
        $display("[SCB]: Actual output is alu_out = %0d\n Expected output is alu_out = %0d\n ",
                 trans.alu_out, excpected_out);
              `uvm_info("[SCB]" , "MISMATCH\n", UVM_LOW);

        $display(
            "****************************************************************************************************");

      end
    end else if ((trans.alu_enable_a == 1'b0) && (trans.alu_enable_b == 1'b1)) begin
      case (trans.alu_op_b)
        2'b00: excpected_out = ~(trans.alu_in_a ^ trans.alu_in_b);
        2'b01: excpected_out = trans.alu_in_a & trans.alu_in_b;
        2'b10: excpected_out = ~(trans.alu_in_a | trans.alu_in_b);
        2'b11: excpected_out = trans.alu_in_a | trans.alu_in_b;
      endcase
      $display("[SCB]: Operating in mode 'b', alu_op_b = %0d, alu_in_a = %0d, alu_in_b = %0d\n ",
               trans.alu_op_b, trans.alu_in_a, trans.alu_in_b);
      if (excpected_out == trans.alu_out) begin
        foreach (event_trigger_b[i]) begin
          if (event_trigger_b[i] == {trans.alu_op_b, excpected_out}) begin
            trigger = 1'b1;
            break;
          end
        end
      end else begin
        $display("[SCB]: Actual output is alu_out = %0d\n Expected output is alu_out = %0d\n ",
                 trans.alu_out, excpected_out);
              `uvm_info("[SCB]" , "MISMATCH\n", UVM_LOW);

        $display(
            "****************************************************************************************************");

      end
    end

    if (trigger == 1'b1) begin
      $display("[SCB]" , "EVENT TRIGGERED \n ", UVM_LOW);
      if (trans.alu_irq == 1'b1) begin
        $display(
            "[SCB]: Actual outputs are alu_out = %0d, alu_irq = %0d\n Expected outputs are alu_out = %0d, alu_irq = %0d\n ",
            trans.alu_out, trans.alu_irq, excpected_out, 1);
`uvm_info("[SCB]" ,"PASSED\n",UVM_LOW);
        $display(
            "****************************************************************************************************");

      end else begin
        $display("[SCB]: Actual alu_irq = %0d\n Expected alu_irq = %0d\n ", trans.alu_irq, 1);
              `uvm_info("[SCB]" , "MISMATCH\n", UVM_LOW);

        $display(
            "****************************************************************************************************");

      end
    end else begin
      if ( (prev_trans.alu_irq == 1'h1) && (prev_trans.alu_irq_clr == 1'b0) && (trans.alu_irq == 1'b1 )) begin
        $display(
            "[SCB]: Actual outputs are alu_out = %0d, alu_irq = %0d\n Expected outputs are alu_out = %0d, alu_irq = %0d\n ",
            trans.alu_out, trans.alu_irq, excpected_out, 1);
        `uvm_info("[SCB]" , "alu_irq was not cleared so it should remain high\n",UVM_LOW);
`uvm_info("[SCB]" ,"PASSED\n",UVM_LOW);
        $display(
            "****************************************************************************************************");

      end else if ((prev_trans.alu_irq_clr == 1'b1) && (trans.alu_irq == 1'b1)) begin
        $display("[SCB]: Actual alu_irq = %0d\n Expected alu_irq = %0d\n ", trans.alu_irq, 0);
        `uvm_info("[SCB]" , "alu_irq should be low\n",UVM_LOW);
              `uvm_info("[SCB]" , "MISMATCH\n", UVM_LOW);

        $display(
            "****************************************************************************************************");

      end else if ((prev_trans.alu_irq_clr == 1'b1) && (trans.alu_irq == 1'b0)) begin
        $display(
            "[SCB]: Actual outputs are alu_out = %0d, alu_irq = %0d\n Expected outputs are alu_out = %0d, alu_irq = %0d\n ",
            trans.alu_out, trans.alu_irq, excpected_out, 0);
`uvm_info("[SCB]" ,"PASSED\n",UVM_LOW);
        $display(
            "****************************************************************************************************");
      end else begin
        $display(
            "[SCB]: Actual outputs are alu_out = %0d, alu_irq = %0d\n Expected outputs are alu_out = %0d, alu_irq = %0d\n ",
            trans.alu_out, trans.alu_irq, excpected_out, 0);
`uvm_info("[SCB]" ,"MISMATCH\n",UVM_LOW);
        $display(
            "****************************************************************************************************");
      end
    end
    trigger = 1'b0;
        end else begin
          `uvm_info("[SCB]" , "alu_enable is off so the outputs should remain the same\n",UVM_LOW);
          if (prev_trans.alu_out != trans.alu_out || prev_trans.alu_irq != trans.alu_irq) begin
            `uvm_info("[SCB]" , "Outputs changed while the alu is not enabled \n",UVM_LOW);
            $display(
                "[SCB]: Previous outputs are alu_out = %0d, alu_irq = %0d\n Current outputs are alu_out = %0d, alu_irq = %0d\n ",
                prev_trans.alu_out, prev_trans.alu_irq, trans.alu_out, trans.alu_irq);
              `uvm_info("[SCB]" , "MISMATCH\n", UVM_LOW);

            $display(
                "****************************************************************************************************");

          end else begin
            $display(
                "[SCB]: Previous outputs are alu_out = %0d, alu_irq = %0d\n Current outputs are alu_out = %0d, alu_irq = %0d\n ",
                prev_trans.alu_out, prev_trans.alu_irq, trans.alu_out, trans.alu_irq);
`uvm_info("[SCB]" ,"PASSED\n",UVM_LOW);
            $display(
                "****************************************************************************************************");

          end
        end
      end else begin
        if (trans.alu_out != 8'b0 || trans.alu_irq != 1'b0) begin
          `uvm_info("[SCB]","Reset is activated but outputs are not low\n",UVM_LOW);
              `uvm_info("[SCB]" , "MISMATCH\n", UVM_LOW);
          $display(
              "****************************************************************************************************");
        end else begin
          `uvm_info("[SCB]" ,"Reset is activated and outputs are low\n", UVM_LOW);
          `uvm_info("[SCB]" ,"PASSED\n",UVM_LOW);
          $display(
              "****************************************************************************************************");
        end
      end

 end
endtask
   
  function new(string name = "scoreboard", uvm_component parent =null);
    super.new(name,parent);
    
  endfunction 
endclass 



