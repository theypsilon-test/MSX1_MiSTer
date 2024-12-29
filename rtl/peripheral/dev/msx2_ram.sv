module msx2_ram (
    cpu_bus_if.device_mp    cpu_bus,
    device_bus              device_bus,
    input  MSX::io_device_t io_device[3],
    output            [7:0] data,
    output            [7:0] data_to_mapper
);

    logic [2:0] mapper_io;
    logic [7:0] sizes[3];
    logic [7:0] data_out[0:2], data_to_mapper_ar[3];
    wire        io_en = cpu_bus.iorq && ~cpu_bus.m1;

    assign data      = data_out[0] & data_out[1] & data_out[2];
    assign data_to_mapper = device_bus.typ == DEV_MSX2_RAM ? data_to_mapper_ar[device_bus.num] : 8'hFF;

    genvar i;
    generate
        for (i = 0; i < 3; i++) begin : msx2_ram_dev_INSTANCES
            wire cs_io_active = (cpu_bus.addr[7:0] & io_device[i].mask) == io_device[i].port;
            wire cs_enable = io_device[i].enable && cs_io_active && io_en;
            msx2_ram_dev msx2_ram_dev_i (
                .clk(cpu_bus.clk),
                .reset(cpu_bus.reset),
                .data(cpu_bus.data),
                .addr(cpu_bus.addr),
                .oe(cs_enable && cpu_bus.rd),  // IO read
                .wr(cs_enable && cpu_bus.wr && cpu_bus.req),  // IO write
                .size(io_device[i].param),
                .q(data_out[i]),
                .data_to_mapper(data_to_mapper_ar[i])
            );
        end
    endgenerate

endmodule

module msx2_ram_dev (
    input              reset,
    input              clk,
    input              oe,
    input              wr,
    input       [15:0] addr,
    input        [7:0] data,
    output       [7:0] q,
    input        [7:0] size,
    output logic [7:0] data_to_mapper
);
    logic [7:0] mem_seg[0:3];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_seg[0] <= 8'd0; // Reset segment FC
            mem_seg[1] <= 8'd0; // Reset segment FD
            mem_seg[2] <= 8'd0; // Reset segment FE
            mem_seg[3] <= 8'd0; // Reset segment FF
        end else if (wr) begin
            mem_seg[addr[1:0]] <= data & (size -1'b1);
            $display("MSX2 RAM WR (size: %x) SEG:%d <= %x", size, addr[1:0], data & (size -1'b1) );
        end
    end

    assign q = oe ? (mem_seg[addr[1:0]] | (~(size -1'b1))) : 8'hFF;
    assign data_to_mapper = mem_seg[addr[15:14]];
endmodule
