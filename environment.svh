/****************************************************************************************************************************************
************************************************* ENVIRONMENT CLASS *************************************************************************
****************************************************************************************************************************************/

class environment extends uvm_env;
`uvm_component_utils(environment)

function new(input string name = "ENV", uvm_component parent);
super.new(name,parent);
endfunction
agent a;
scoreboard scb;
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
a = agent::type_id::create("AGENT",this);
scb = scoreboard::type_id::create("SCOREBOARD",this);
endfunction

 virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
a.m.send_trans.connect(scb.recv_trans);
endfunction
endclass
