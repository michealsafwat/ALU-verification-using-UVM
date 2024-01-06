 

/****************************************************************************************************************************************
************************************************* TEST CLASS *************************************************************************
****************************************************************************************************************************************/
class test extends uvm_test;
`uvm_component_utils(test)

function new(input string name = "TEST", uvm_component parent);
super.new(name,parent);
endfunction
virtual ALU_IF alu_if;
base_sequence seq;
environment e;
event done;
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
e = environment::type_id::create("ENV",this);
seq = base_sequence::type_id::create("SEQUENCE",this);
  seq.count = 2;

endfunction
 virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
e.a.m.done=done;
 seq.done=done;
endfunction
  
virtual task run_phase(uvm_phase phase);
super.run_phase (phase);
phase.raise_objection(this);
seq.start(e.a.s);
phase.drop_objection(this);
endtask
endclass
