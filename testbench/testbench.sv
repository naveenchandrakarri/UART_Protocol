`timescale 1ns / 1ps 

`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;

function new(input string path = "transaction");
super.new(path);
endfunction

rand bit newd;
rand bit[7:0] din;
bit done_rx, done_tx;
bit [7:0] rx_data;
rand bit [2:0] baud_sel;
rand bit [3:0] length;
rand bit parity_type, parity_en;
bit frame_err, parity_err;

constraint cntrl{ newd == 1;
                  parity_type dist { 0:= 50 , 1:= 50};
                  parity_en dist { 0:= 30 , 1:= 70};
                 length inside{5,6,7,8};
                 baud_sel inside{3,4,5};} 

`uvm_object_utils_begin(transaction)
`uvm_field_int(newd , UVM_DEFAULT)
`uvm_field_int(length , UVM_DEFAULT)
`uvm_field_int(parity_type , UVM_DEFAULT)
`uvm_field_int(parity_en , UVM_DEFAULT)
`uvm_field_int(din , UVM_DEFAULT)
`uvm_field_int(done_rx , UVM_DEFAULT)
`uvm_field_int(done_tx , UVM_DEFAULT)
`uvm_field_int(rx_data , UVM_DEFAULT)
`uvm_field_int(baud_sel , UVM_DEFAULT)
`uvm_field_int(frame_err , UVM_DEFAULT)
`uvm_field_int(parity_err, UVM_DEFAULT)
`uvm_object_utils_end

endclass

class generator extends uvm_sequence#(transaction);
`uvm_object_utils(generator)

transaction tr;

function new(string path = "generator");
super.new(path);
endfunction

virtual task body();
tr = transaction::type_id::create("tr");
  repeat(13) begin
  start_item(tr);
  assert(tr.randomize());
  `uvm_info("GEN",tr.sprint(),UVM_NONE);
  finish_item(tr);
end
endtask

endclass

class driver extends uvm_driver#(transaction);
`uvm_component_utils(driver)

transaction tr;
virtual uff_if mif;

function new(input string inst = "driver", uvm_component parent = null);
super.new(inst,parent);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db#(virtual uff_if)::get(this,"","mif",mif)) begin 
  `uvm_error("DRV","uvm_config_db is failed");
end
endfunction

task reset_dut();
mif.rst <= 1;
mif.din <= 0;
mif.newd <= 0;
mif.parity_en <= 0;
mif.parity_type <= 0;
mif.length <= 0;
mif.baud_sel <= 0;
repeat(5) @(posedge mif.clk);
mif.rst <= 0;
`uvm_info("DRV","reset done",UVM_NONE);
endtask

virtual task run_phase(uvm_phase phase);
reset_dut();
forever begin
  tr = transaction::type_id::create("tr");
seq_item_port.get_next_item(tr);
mif.baud_sel <= tr.baud_sel;
mif.din <= tr.din;
mif.newd <= tr.newd;
mif.parity_en <= tr.parity_en;
mif.parity_type <= tr.parity_type;
mif.length <= tr.length;
@(posedge mif.clk);
`uvm_info("DRV",tr.sprint(),UVM_NONE);
  `uvm_info("DRV","WAITING FOR DONE_TX",UVM_NONE);

  @(posedge mif.done_tx);
  mif.newd <= 1'b0;
  @(posedge mif.done_rx);
@(posedge mif.clk);
seq_item_port.item_done();
end
endtask
endclass

class monitor extends uvm_monitor;
`uvm_component_utils(monitor)

transaction tr;
virtual uff_if mif;
uvm_analysis_port#(transaction) send;

function new(string inst = "monitor", uvm_component c);
super.new(inst,c);
send = new("send",this);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db#(virtual uff_if)::get(this,"","mif",mif)) begin 
  `uvm_error("MON","uvm_config_db is failed");
end
endfunction

virtual task run_phase(uvm_phase phase);
@(negedge mif.rst);
forever begin
  tr = transaction::type_id::create("tr");
@(posedge mif.newd);
tr.din = mif.din;
tr.newd = mif.newd ;
tr.parity_en = mif.parity_en;
tr.parity_type = mif.parity_type;
tr.length = mif.length;
tr.baud_sel = mif.baud_sel;
@(posedge mif.done_rx);
tr.rx_data = mif.rx_data;
tr.parity_err = mif.parity_err;
tr.frame_err = mif.frame_err;
`uvm_info("MON",tr.sprint(),UVM_NONE);
send.write(tr);
@(posedge mif.clk);
end
endtask
endclass

class sco extends uvm_scoreboard;
`uvm_component_utils(sco)

transaction tr;
uvm_analysis_imp#(transaction,sco) rec;

function new(string inst = "sco", uvm_component c);
super.new(inst,c);
rec = new("rec",this);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
tr = transaction::type_id::create("tr");
endfunction

virtual function void write(transaction tr);
`uvm_info("SCO",tr.sprint(),UVM_NONE);
case (tr.length)
4'd5 : begin
  if(tr.rx_data[4:0] == tr.din[4:0]) begin
    `uvm_info("SCO","test passed",UVM_NONE);
  end
  else begin
    `uvm_info("SCO","test failed",UVM_NONE); 
  end
end
4'd6 : begin
  if(tr.rx_data[5:0] == tr.din[5:0]) begin
    `uvm_info("SCO","test passed",UVM_NONE);
  end
  else begin
    `uvm_info("SCO","test failed",UVM_NONE); 
  end
end
4'd7 : begin
  if(tr.rx_data[6:0] == tr.din[6:0]) begin
    `uvm_info("SCO","test passed",UVM_NONE);
  end
  else begin
    `uvm_info("SCO","test failed",UVM_NONE); 
  end
end
4'd8 : begin
  if(tr.rx_data[7:0] == tr.din[7:0]) begin
    `uvm_info("SCO","test passed",UVM_NONE);
  end
  else begin
    `uvm_info("SCO","test failed",UVM_NONE); 
  end
end
endcase
endfunction

endclass

class uart_cov extends uvm_subscriber #(transaction);

`uvm_component_utils(uart_cov)

transaction tr;

covergroup uart_cg;
  option.per_instance = 1;
  option.name = "coverage";
  cp_baud : coverpoint tr.baud_sel
  {
    bins b1200   = {0};
    bins b2400   = {1};
    bins b4800   = {2};
    bins b9600   = {3};
    bins b115200 = {4};
    bins b921600 = {5};
  }

  cp_len : coverpoint tr.length
  {
    bins len5 = {5};
    bins len6 = {6};
    bins len7 = {7};
    bins len8 = {8};
    illegal_bins unused_a = {0,1,2,3,4};
  }

  cp_pen : coverpoint tr.parity_en
  {
    bins off = {0};
    bins on  = {1};
  }

  cp_ptype : coverpoint tr.parity_type
  {
    bins even = {0};
    bins odd  = {1};
  }

  cp_ferr : coverpoint tr.frame_err;
  cp_perr : coverpoint tr.parity_err;

  baud_len_cross : cross cp_baud, cp_len;

  parity_cross : cross cp_pen, cp_ptype;
  endgroup
  
  function new(string name="uart_cov",
             uvm_component parent=null);

  super.new(name,parent);

  uart_cg = new();

endfunction
  
  virtual function void write(transaction t);

  tr = t;

  uart_cg.sample();

endfunction
  
  function void report_phase(uvm_phase phase);

  `uvm_info("COV",
    $sformatf("Overall Functional Coverage = %0.2f%%",
              uart_cg.get_coverage()),
    UVM_NONE)
    
    $display("Overall Coverage = %0.2f%%",
           uart_cg.get_coverage());

endfunction

  endclass
  
class agent extends uvm_agent;
`uvm_component_utils(agent)

driver d;
monitor m;
uvm_sequencer#(transaction) seqr;

function new(string inst = "agent", uvm_component c);
super.new(inst,c);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
d = driver::type_id::create("d",this);
m = monitor::type_id::create("m",this);
seqr = uvm_sequencer#(transaction)::type_id::create("seqr",this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
d.seq_item_port.connect(seqr.seq_item_export);
endfunction

endclass

class env extends uvm_env;
`uvm_component_utils(env)

agent a;
sco s;
uart_cov cov;
  
function new(string inst = "env", uvm_component c);
super.new(inst,c);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
a = agent::type_id::create("a",this);
s = sco::type_id::create("s",this);
cov = uart_cov::type_id::create("cov",this);
endfunction

virtual function void connect_phase(uvm_phase phase);
super.connect_phase(phase);
a.m.send.connect(s.rec);
a.m.send.connect(cov.analysis_export);
endfunction

endclass

class test extends uvm_test;
`uvm_component_utils(test)

env e;
generator gen ;

function new(string inst = "test", uvm_component c);
super.new(inst,c);
endfunction

virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
e = env::type_id::create("e",this);
gen = generator::type_id::create("gen");
endfunction

virtual task run_phase(uvm_phase phase);
phase.raise_objection(this);
gen.start(e.a.seqr);
phase.drop_objection(this);
endtask

endclass


module tb;
uff_if mif();
uart u(mif.clk, mif.rst, mif.baud_sel, mif.parity_en, mif.parity_type, mif.length,
 mif.newd, mif.din, mif.done_rx, mif.rx_data, mif.frame_err, mif.parity_err, mif.done_tx);

initial begin 
  mif.clk <= 0;
end

always #5 mif.clk = ~mif.clk;
 
initial begin
$dumpfile("dump.vcd");
$dumpvars;
end
  
initial begin  
uvm_config_db #(virtual uff_if)::set(null, "*", "mif", mif);
run_test("test");
end
  
  property valid_length;
    @(posedge mif.clk)
    disable iff (mif.rst)
    mif.newd |-> (mif.length inside {5,6,7,8});
endproperty

a_valid_length : assert property(valid_length)
  else $error("Invalid UART length detected");
  
property valid_baud;
  @(posedge mif.clk)
  disable iff (mif.rst)
  mif.newd |-> (mif.baud_sel inside {0,1,2,3,4,5});
endproperty

  a_valid_baud : assert property(valid_baud)
    else $error("Invalid UART baud detected");

    property tx_idle;
      @(posedge mif.clk)
      disable iff(mif.rst)
      (u.t.state == u.t.idle) |-> u.t.tx == 1;
    endproperty
 
    a_tx_idle : assert property(tx_idle)
      else $error("UART Protocol violated . tx is not high when ideal");
      
 property parity_enabled_goes_to_parity;
    @(posedge mif.clk)
    disable iff(mif.rst)
  mif.parity_en && $rose(mif.newd)
    |-> ##[1:$] (u.t.state == u.t.parity);
endproperty
      
      a_parity_enable : assert property(parity_enabled_goes_to_parity)
        else $error("parity state missed");
        
        property complete_tx;
          @(posedge mif.clk)
          disable iff(mif.rst)
          $rose(mif.newd) |-> ##[1:100000] (mif.done_tx == 1);
        endproperty
        a_complete : assert property(complete_tx)
          else $error("UART failed to transmit the data");
endmodule
