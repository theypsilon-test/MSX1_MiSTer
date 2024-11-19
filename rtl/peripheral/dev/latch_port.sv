module latch_port (
    cpu_bus_if.device_mp    cpu_bus,                                // Interface for CPU communication
    device_bus              device_bus,                             // Interface for device control
    input  [2:0]            dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
    input  MSX::io_device_t io_device[16],                          // Array of IO devices with port and mask info
    output            [7:0] data_to_mapper
);

    // Signals
    logic [2:0] mapper_io;
    logic [7:0] data_to_mapper_ar[0:2];
    wire       io_en = cpu_bus.iorq && ~cpu_bus.m1;

    // Instantiate IO decoder to generate enable signals and parameters
    io_decoder #(.DEV_NAME(DEV_LATCH_PORT)) latch_port_decoder (
        .cpu_addr(cpu_bus.addr[7:0]),
        .io_device(io_device),
        .enable(mapper_io),
        .params()
    );

    // Generate request and output signals
    assign data_to_mapper = device_bus.typ == DEV_LATCH_PORT ? data_to_mapper_ar[device_bus.num] : 8'hFF;
    
    genvar i;
    generate
        for (i = 0; i < 3; i++) begin : latch_port_dev_INSTANCES
            latch_port_dev latch_port_dev_i (
                .clk(cpu_bus.clk),
                .reset(cpu_bus.reset),
                .data(cpu_bus.data),
                .wr(cpu_bus.req && mapper_io[i] && io_en && cpu_bus.wr),  // IO write
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