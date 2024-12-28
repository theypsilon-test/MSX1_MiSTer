module latch_port (
    cpu_bus_if.device_mp    cpu_bus,                                // Interface for CPU communication
    device_bus              device_bus,                             // Interface for device control
    input  MSX::io_device_t io_device[3],                           // Array of IO devices with port and mask info
    output            [7:0] data_to_mapper
);

    // Signals
    logic [2:0] mapper_io;
    logic [7:0] data_to_mapper_ar[0:2];

    // Generate request and output signals
    assign data_to_mapper = device_bus.typ == DEV_LATCH_PORT ? data_to_mapper_ar[device_bus.num] : 8'hFF;
    
    // IO operation signal  
    wire       io_en = cpu_bus.iorq && ~cpu_bus.m1;

    genvar i;
    generate
        for (i = 0; i < 3; i++) begin : latch_port_dev_INSTANCES
            wire cs_io_active = (cpu_bus.addr[7:0] & io_device[i].mask) == io_device[i].port;
            wire cs_enable = io_device[i].enable && cs_io_active && io_en;
            latch_port_dev latch_port_dev_i (
                .clk(cpu_bus.clk),
                .reset(cpu_bus.reset),
                .data(cpu_bus.data),
                .wr(cs_enable && cpu_bus.wr && cpu_bus.req),  // IO write
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
    always_ff @(posedge clk) begin
        if (reset) begin
            data_to_mapper <= 8'd0;
        end else begin
            if (wr) begin
                data_to_mapper <= data;
            end
        end
    end

endmodule