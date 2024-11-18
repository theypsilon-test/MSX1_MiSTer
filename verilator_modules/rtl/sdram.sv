module sdram
(
    input             init,        // reset to initialize RAM
    input             clk,         // clock 64MHz
   
    input             doRefresh,

    inout  reg [15:0] SDRAM_DQ,    // 16 bit bidirectional data bus
    output reg [12:0] SDRAM_A,     // 13 bit multiplexed address bus
    output            SDRAM_DQML,  // two byte masks
    output            SDRAM_DQMH,  // 
    output reg  [1:0] SDRAM_BA,    // two banks
    output            SDRAM_nCS,   // a single chip select
    output            SDRAM_nWE,   // write enable
    output            SDRAM_nRAS,  // row address select
    output            SDRAM_nCAS,  // columns address select
    output            SDRAM_CKE,   // clock enable
    output            SDRAM_CLK,   // clock for chip

    input      [26:0] ch1_addr /* verilator public */,    // 25 bit address for 8bit mode. addr[0] = 0 for 16bit mode for correct operations.
    output reg  [7:0] ch1_dout /* verilator public */,    // data output to cpu
    input       [7:0] ch1_din /* verilator public */,
    input             ch1_req /* verilator public */,     // request
    input             ch1_rnw /* verilator public */,     // 1 - read, 0 - write
    output reg        ch1_ready /* verilator public */,
    
    input      [26:0] ch2_addr /* verilator public */,    
    output reg  [7:0] ch2_dout /* verilator public */,    
	input       [7:0] ch2_din /* verilator public */,     
    input             ch2_req /* verilator public */,
	input             ch2_rnw /* verilator public */,     // 1 - read, 0 - write
    output reg        ch2_ready /* verilator public */,
    output reg        ch2_done /* verilator public */,

    input      [26:0] ch3_addr /* verilator public */,
    output reg  [7:0] ch3_dout /* verilator public */,
    input       [7:0] ch3_din /* verilator public */,
    input             ch3_req /* verilator public */,
    input             ch3_rnw /* verilator public */,     // 1 - read, 0 - write
    output reg        ch3_ready /* verilator public */,
	output reg        ch3_done /* verilator public */
);

endmodule