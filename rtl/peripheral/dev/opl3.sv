module opl3 (
    cpu_bus         cpu_bus,            // Interface for CPU communication
    device_bus      device_bus,         // Interface for device control
    input     [2:0] dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
    input MSX::io_device_t   io_device[16],  // Array of IO devices with port and mask info
    output signed [15:0] sound          // Combined sound output
);

    assign sound = (dev_enable[DEV_OPL3][0] ? sound_OPL3[0] : '0) +
                   (dev_enable[DEV_OPL3][1] ? sound_OPL3[1] : '0) +
                   (dev_enable[DEV_OPL3][2] ? sound_OPL3[2] : '0);

    // Enable signals for OPL3
    wire [2:0] opl3_en; 
    io_decoder #(.DEV_NAME(DEV_OPL3)) opl_decoder (
        .cpu_addr(cpu_bus.addr[7:0]),
        .io_device(io_device),
        .enable(opl3_en)
    );
    
    // Control logic for enabling or disabling OPL3 channels
    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            // Default to all OPL3 channels enabled
            opl3_enabled <= 3'b111;
        end else if (device_bus.typ == DEV_OPL3 && device_bus.num < 3) begin
            // Update enabled status for the specific OPL3 channel
            opl3_enabled[device_bus.num] <= device_bus.en;
        end
    end
    
    // IO operation signal
    wire io_op = cpu_bus.iorq && ~cpu_bus.m1;
    
    // OPL3 instances for sound generation
    wire signed [15:0] sound_OPL3[0:2];
    logic [2:0] opl3_enabled;
    genvar i;

    generate
        for (i = 0; i < 3; i++) begin : OPL3_INSTANCES
            jt2413 OPL3_i (
                .clk(cpu_bus.clk),
                .rst(cpu_bus.reset),
                .cen(cpu_bus.clk_en),
                .din(cpu_bus.data),
                .addr(cpu_bus.addr[0]),
                .cs_n(~(io_op && opl3_en[i] && opl3_enabled[i])),  // Chip select for OPL3
                .wr_n(~(cpu_bus.wr | device_bus.we)),              // Write enable
                .snd(sound_OPL3[i]),                               // Sound output
                .sample()                                          // Sample output (unused)
            );
        end
    endgenerate

endmodule
