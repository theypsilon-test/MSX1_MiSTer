module scc (
    clock_bus_if    clock_bus,         // Interface for clock
    cpu_bus_if      cpu_bus,           // Interface for CPU communication
    device_bus      device_bus,        // Interface for device control
    input     [2:0] dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
    input MSX::io_device_t   io_device[16],  // Array of IO devices with port and mask info
    output signed [15:0] sound,        // Combined sound output from SCC devices
    output   [7:0]  data,              // Data output from SCC device
    output          output_rq          // Output request signal
);

    // Combine sound output from two SCC channels if enabled
    assign sound = (dev_enable[DEV_SCC][0] ? {sound_SCC[0][14], sound_SCC[0]} : '0) +
                   (dev_enable[DEV_SCC][1] ? {sound_SCC[1][14], sound_SCC[1]} : '0);

    // Control logic for enabling or disabling SCC channels
    always @(posedge clock_bus.clk_sys) begin
        if (clock_bus.reset) begin
            // On reset, disable all SCC channels
            scc_enabled <= 2'b00;
        end else if (device_bus.typ == DEV_SCC && device_bus.num < 2) begin
            // Update enabled status for the specific SCC channel
            scc_enabled[device_bus.num[0]] <= device_bus.en;
        end
    end

    // Define sound and data arrays for SCC devices
    wire signed [14:0] sound_SCC[0:1];  // Sound output for SCC channels (2 channels)
    wire [7:0] data_SCC[2];             // Data output for SCC channels (2 channels)
    logic [1:0] scc_enabled;            // Enable flags for SCC channels

    // Data output and request signal: output data only if the device is selected and read is requested
    assign {output_rq, data} = cs && cpu_bus.rd ? {1'b1, data_SCC[device_bus.num[0]]} : 9'h0FF;

    // SCC area check: determine if the address is within the SCC memory range (0x9800-0xA000)
    wire SCC_area = (cpu_bus.addr >= 16'h9800) && (cpu_bus.addr < 16'hA000);

    // Chip select signal: active if the device is an SCC and the address is in the SCC area, and the SCC channel is enabled
    wire cs = (device_bus.typ == DEV_SCC) && SCC_area && scc_enabled[device_bus.num[0]];

    // Generate SCC instances for two channels
    genvar i;
    generate
        for (i = 0; i < 2; i++) begin : SCC_INSTANCES
            scc_wave scc_wave_i (
                .clk(clock_bus.clk_sys),        // Clock signal
                .clkena(clock_bus.ce_3m58_p),  // Clock enable signal
                .reset(clock_bus.reset),    // Reset signal
                .req(cs && device_bus.num == i),  // Request signal for SCC
                .ack(),                   // Acknowledge signal (not connected)
                .wrt(cpu_bus.wr),         // Write enable signal
                .adr(cpu_bus.addr[7:0]),  // Address bus (8 bits)
                .dbo(cpu_bus.data),       // Data output from CPU to SCC
                .dbi(data_SCC[i]),        // Data input from SCC to CPU
                .wave(sound_SCC[i]),      // Sound output from SCC
                .sccPlusChip('0),         // SCC Plus chip flag (default 0)
                .sccPlusMode('0)          // SCC Plus mode flag (default 0)
            );
        end
    endgenerate

endmodule
