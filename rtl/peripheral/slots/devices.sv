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

assign sound = (dev_enable[DEV_OPL3][0] ? sound_OPL3[0] : '0) +
               (dev_enable[DEV_OPL3][1] ? sound_OPL3[1] : '0) +
               (dev_enable[DEV_OPL3][2] ? sound_OPL3[2] : '0) ;

// OPL3
wire signed [15:0] sound_OPL3[0:2];
genvar i;
generate
    for (i = 0; i < 3; i++) begin : OPL3_INSTANCES
        jt2413 OPL3_i
        (
            .clk(clk),
            .rst(reset),
            .cen(clk_en),
            .din(dev_din),
            .addr(dev_addr[0]),
            .cs_n(~(device == DEV_OPL3 && device_num == i && dev_enable[DEV_OPL3][i])),
            .wr_n(~dev_wr),
            .snd(sound_OPL3[i]),
            .sample()
        );
    end
endgenerate

endmodule
