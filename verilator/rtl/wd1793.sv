module wd1793 #(parameter RWMODE=0, EDSK=1)
(
	input        clk_sys,     // sys clock
	input        ce,          // ce at CPU clock rate
	input        reset,	     // async reset
	input        io_en,
	input        rd,          // i/o read
	input        wr,          // i/o write
	input  [1:0] addr,        // i/o port addr
	input  [7:0] din,         // i/o data in
	output [7:0] dout,        // i/o data out
	output       drq,         // DMA request
	output       intrq,
	output       busy,

	input        wp,          // write protect

	input  [2:0] size_code,
	input        layout,      // 0 = Track-Side-Sector, 1 - Side-Track-Sector
	input        side,
	input        ready,

	// SD access (RWMODE == 1)
	input        img_mounted, // signaling that new image has been mounted
	input [19:0] img_size,    // size of image in bytes. 1MB MAX!
	output       prepare,
	output[31:0] sd_lba,
	output reg   sd_rd,
	output reg   sd_wr,
	input        sd_ack,
	input  [8:0] sd_buff_addr,
	input  [7:0] sd_buff_dout,
	output [7:0] sd_buff_din,
	input        sd_buff_wr,

	// RAM access (RWMODE == 0)
	input        input_active,
	input [19:0] input_addr,
	input  [7:0] input_data,
	input        input_wr,
	output[19:0] buff_addr,	  // buffer RAM address
	output       buff_read,	  // buffer RAM read enable
	input  [7:0] buff_din     // buffer RAM data input
);

endmodule