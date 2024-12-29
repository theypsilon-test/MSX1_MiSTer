module latch_port (
    cpu_bus_if.device_mp    cpu_bus,
    device_bus              device_bus,
    input  MSX::io_device_t io_device[3],
    output            [7:0] data_to_mapper
);

    logic [7:0] data_to_mapper_ar[0:2];

    assign data_to_mapper = device_bus.typ == DEV_LATCH_PORT ? data_to_mapper_ar[device_bus.num] : 8'hFF;

    wire io_en = cpu_bus.iorq && ~cpu_bus.m1;

    genvar i;
    generate
        for (i = 0; i < 3; i++) begin : LATCH_PORT_DEV_INSTANCES
            wire cs_active = (cpu_bus.addr[7:0] & io_device[i].mask) == io_device[i].port;
            wire cs_enable = io_device[i].enable && cs_active && io_en;

            latch_port_dev latch_port_dev_i (
                .clk(cpu_bus.clk),
                .reset(cpu_bus.reset),
                .data(cpu_bus.data),
                .wr(cs_enable && cpu_bus.wr && cpu_bus.req),
                .data_to_mapper(data_to_mapper_ar[i])
            );
        end
    endgenerate

endmodule

module latch_port_dev (
    input              clk,
    input              reset,
    input        [7:0] data,
    input              wr,
    output logic [7:0] data_to_mapper
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            data_to_mapper <= 8'd0;
        end else if (wr) begin
            data_to_mapper <= data;
        end
    end

endmodule
