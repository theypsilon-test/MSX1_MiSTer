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

module altsyncram (
	input                  clock0 /* verilator public */,   //   (clk_sys),
	input [widthad_a-1:0] address_a /* verilator public */,  //({sd_buf,sd_buff_addr}),
	input            [7:0] data_a /* verilator public */,   //(sd_buff_dout),
	input                  wren_a /* verilator public */,   // (sd_ack & sd_buff_wr),
	output           [7:0] q_a /* verilator public */,      // (sd_buff_din),

	input                  clock1 /* verilator public */,   // (clk_spi),
	input [widthad_b-1:0] address_b /* verilator public */,//({spi_buf,buffer_ptr}),
	input            [7:0] data_b /* verilator public */,   //(buffer_din),
	input                  wren_b /* verilator public */,    //(buffer_wr),
	output           [7:0] q_b /* verilator public */,       //(buffer_dout),

	input aclr0,
	input aclr1,
	input addressstall_a,
	input addressstall_b,
	input byteena_a,
	input byteena_b,
	input clocken0,
	input clocken1,
	input clocken2,
	input clocken3,
	output eccstatus,
	input rden_a,
	input rden_b
);
  parameter widthad_a /* verilator public */ = 1;
  parameter widthad_b /* verilator public */ = 1;

  parameter numwords_a = 1;
	parameter width_a    = 8;
	parameter numwords_b = 1;
	parameter width_b    = 8;
	parameter address_reg_b = "CLOCK1";
	parameter clock_enable_input_a = "BYPASS";
	parameter clock_enable_input_b = "BYPASS";
	parameter clock_enable_output_a = "BYPASS";
	parameter clock_enable_output_b = "BYPASS";
	parameter indata_reg_b = "CLOCK1";
	parameter intended_device_family = "Cyclone V";
	parameter lpm_type = "altsyncram";
	parameter operation_mode = "BIDIR_DUAL_PORT";
	parameter outdata_aclr_a = "NONE";
	parameter outdata_aclr_b = "NONE";
	parameter outdata_reg_a = "UNREGISTERED";
	parameter outdata_reg_b = "UNREGISTERED";
	parameter power_up_uninitialized = "FALSE";
	parameter read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ";
	parameter read_during_write_mode_port_b = "NEW_DATA_NO_NBE_READ";
	parameter width_byteena_a = 1;
	parameter width_byteena_b = 1;
	parameter wrcontrol_wraddress_reg_b = "CLOCK1";
endmodule