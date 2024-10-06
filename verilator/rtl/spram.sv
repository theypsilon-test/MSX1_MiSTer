module spram (
  input                   clock,
  input                   wren /* verilator public */,
  input  [addr_width-1:0] address /* verilator public */, 
  input  [7:0]            data /* verilator public */,
  output [7:0]            q /* verilator public */
);

  parameter addr_width /* verilator public */ = 1;
  parameter mem_name = "UNNAMED";
  parameter mem_init_file = "none";

endmodule

module dpram (
  input                   clock,
  input                   wren_a /* verilator public */,
  input                   wren_b /* verilator public */,
  input  [addr_width-1:0] address_a /* verilator public */, 
  input  [addr_width-1:0] address_b /* verilator public */, 
  input  [7:0]            data_a /* verilator public */,
  input  [7:0]            data_b /* verilator public */,
  output [7:0]            q_a /* verilator public */,
  output [7:0]            q_b /* verilator public */
);

  parameter addr_width /* verilator public */ = 1;
  parameter mem_name = "UNNAMED";
  parameter mem_init_file = "none";

endmodule
