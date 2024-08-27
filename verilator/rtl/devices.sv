module devices
(
    input           clk,
    input           clk_en,
    input           reset,
    input     [2:0] dev_enable[0:(1 << $bits(device_t))-1], 
    input  device_t device,
    input     [1:0] device_num,
    input    [15:0] dev_addr,
    input     [7:0] dev_din,
    input     [7:0] dev_dout,
    input           dev_wr,
    input           dev_rd,
    output signed [15:0] sound
);

endmodule