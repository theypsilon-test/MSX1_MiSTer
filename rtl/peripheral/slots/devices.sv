/*verilator tracing_on*/
module devices
(
    input           clk,
    input           clk_en,
    input           reset,
    input           cpu_iorq,
    input           cpu_rd,
    input           cpu_wr,
    input           cpu_m1,
    input     [7:0] cpu_data,
    input    [15:0] cpu_addr,
    input     [2:0] dev_enable[0:(1 << $bits(device_t))-1], 
    input  device_t device,
    input MSX::io_device_t   io_device[16],
    input     [1:0] device_num,
    //input    [15:0] dev_addr,
    //input     [7:0] dev_din,
    input     [7:0] dev_dout,
    input           dev_wr,
    input           dev_rd,
    input           dev_en,
    output signed [15:0] sound
);

assign sound = (dev_enable[DEV_OPL3][0] ? sound_OPL3[0] : '0) +
               (dev_enable[DEV_OPL3][1] ? sound_OPL3[1] : '0) +
               (dev_enable[DEV_OPL3][2] ? sound_OPL3[2] : '0) ;

wire io_op = cpu_iorq && ~cpu_m1;

wire [2:0] opl3_en; 
io_decoder #(.DEV_NAME(DEV_OPL3)) opl
(
    .cpu_addr(cpu_addr[7:0]),
    .io_device(io_device),
    .enable(opl3_en)
);

// OPL3
wire signed [15:0] sound_OPL3[0:2];
logic [2:0] opl3_enabled;
genvar i;
generate
    for (i = 0; i < 3; i++) begin : OPL3_INSTANCES
        jt2413 OPL3_i
        (
            .clk(clk),
            .rst(reset),
            .cen(clk_en),
            .din(cpu_data),
            .addr(cpu_addr[0]),
            //.cs_n(~(device == DEV_OPL3 && device_num == i && dev_enable[DEV_OPL3][i])),
            .cs_n(~(io_op && opl3_en[i] && opl3_enabled[i])),
            //.wr_n(~dev_wr),
            .wr_n(~(cpu_wr | dev_wr)),
            .snd(sound_OPL3[i]),
            .sample()
        );
    end
endgenerate

always @(posedge clk) begin
    if (reset) begin
        opl3_enabled <= 3'b111; // Default enabled, všechny bity nastavené na 1
    end else if (device == DEV_OPL3 && device_num < 3) begin
        opl3_enabled[device_num] <= dev_en;
    end
end

endmodule


module io_decoder (
    input  logic [7:0]           cpu_addr,
    input  MSX::io_device_t      io_device[16],
    output logic [2:0]           enable
);
    parameter DEV_NAME;

    assign enable = 
                      ((cpu_addr & io_device[0].mask) == io_device[0].port && io_device[0].id == DEV_NAME ? (3'b001 << io_device[0].num) : 3'b000) |
                      ((cpu_addr & io_device[1].mask) == io_device[1].port && io_device[1].id == DEV_NAME ? (3'b001 << io_device[1].num) : 3'b000) |
                      ((cpu_addr & io_device[2].mask) == io_device[2].port && io_device[2].id == DEV_NAME ? (3'b001 << io_device[2].num) : 3'b000) |
                      ((cpu_addr & io_device[3].mask) == io_device[3].port && io_device[3].id == DEV_NAME ? (3'b001 << io_device[3].num) : 3'b000) |
                      ((cpu_addr & io_device[4].mask) == io_device[4].port && io_device[4].id == DEV_NAME ? (3'b001 << io_device[4].num) : 3'b000) |
                      ((cpu_addr & io_device[5].mask) == io_device[5].port && io_device[5].id == DEV_NAME ? (3'b001 << io_device[5].num) : 3'b000) |
                      ((cpu_addr & io_device[6].mask) == io_device[6].port && io_device[6].id == DEV_NAME ? (3'b001 << io_device[6].num) : 3'b000) |
                      ((cpu_addr & io_device[7].mask) == io_device[7].port && io_device[7].id == DEV_NAME ? (3'b001 << io_device[7].num) : 3'b000) |
                      ((cpu_addr & io_device[8].mask) == io_device[8].port && io_device[8].id == DEV_NAME ? (3'b001 << io_device[8].num) : 3'b000) |
                      ((cpu_addr & io_device[9].mask) == io_device[9].port && io_device[9].id == DEV_NAME ? (3'b001 << io_device[9].num) : 3'b000) |
                      ((cpu_addr & io_device[10].mask) == io_device[10].port && io_device[10].id == DEV_NAME ? (3'b001 << io_device[10].num) : 3'b000) |
                      ((cpu_addr & io_device[11].mask) == io_device[11].port && io_device[11].id == DEV_NAME ? (3'b001 << io_device[11].num) : 3'b000) |
                      ((cpu_addr & io_device[12].mask) == io_device[12].port && io_device[12].id == DEV_NAME ? (3'b001 << io_device[12].num) : 3'b000) |
                      ((cpu_addr & io_device[13].mask) == io_device[13].port && io_device[13].id == DEV_NAME ? (3'b001 << io_device[13].num) : 3'b000) |
                      ((cpu_addr & io_device[14].mask) == io_device[14].port && io_device[14].id == DEV_NAME ? (3'b001 << io_device[14].num) : 3'b000) |
                      ((cpu_addr & io_device[15].mask) == io_device[15].port && io_device[15].id == DEV_NAME ? (3'b001 << io_device[15].num) : 3'b000);

endmodule
