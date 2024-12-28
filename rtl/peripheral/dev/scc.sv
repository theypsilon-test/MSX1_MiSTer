module scc (
    cpu_bus_if.device_mp   cpu_bus,                                 // Interface for CPU communication
    device_bus             device_bus,                              // Interface for device control
    input MSX::io_device_t io_device[3],                            // Array of IO devices with port and mask info
    output   signed [15:0] sound,                                   // Combined sound output from SCC devices
    output           [7:0] data                                     // Data output from SCC device
);

    // Combine sound output from two SCC channels if enabled
    assign sound = (io_device[0].enable ? {sound_SCC[0][14], sound_SCC[0]} : '0) +
                   (io_device[1].enable ? {sound_SCC[1][14], sound_SCC[1]} : '0);

    // Control logic for enabling or disabling SCC channels
    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            // On reset, disable all SCC channels
            scc_mode    <= 2'b00;
            scc_plus    <= 2'b00;
        end else if (device_bus.typ == DEV_SCC && device_bus.num < 2) begin
            // Update enabled status for the specific SCC channel
            scc_mode[device_bus.num[0]]    <= device_bus.mode;
            scc_plus[device_bus.num[0]]    <= device_bus.param;
        end
    end

    // Define sound and data arrays for SCC devices
    wire signed [14:0] sound_SCC[0:1];  // Sound output for SCC channels (2 channels)
    wire [7:0] data_SCC[2];             // Data output for SCC channels (2 channels)
    logic [1:0] scc_mode;               // Mode flags for SCC+ 
    logic [1:0] scc_plus;               // SCC typ 0/1 - SCC/SCC+

    // Chip select signal: active if the device is an SCC and the address is in the SCC area, and the SCC channel is enabled
    wire cs = device_bus.typ == DEV_SCC && device_bus.en;

    // Data output and request signal: output data only if the device is selected and read is requested
    assign data = cs && cpu_bus.rd ? data_SCC[device_bus.num[0]] : 8'hFF;

    // Generate SCC instances for two channels
    genvar i;
    generate
        for (i = 0; i < 2; i++) begin : SCC_INSTANCES
            scc_wave scc_wave_i (
                .clk(cpu_bus.clk),                              // Clock signal
                .clkena(cpu_bus.clk_en),                        // Clock enable signal
                .reset(cpu_bus.reset),                          // Reset signal
                .req(cs && device_bus.num == i),                // Request signal for SCC
                .ack(),                                         // Acknowledge signal (not connected)
                .wrt(cpu_bus.wr && cpu_bus.req),                // Write enable signal
                .adr(cpu_bus.addr[7:0]),                        // Address bus (8 bits)
                .dbo(cpu_bus.data),                             // Data output from CPU to SCC
                .dbi(data_SCC[i]),                              // Data input from SCC to CPU
                .wave(sound_SCC[i]),                            // Sound output from SCC
                .sccPlusChip(scc_plus[i]),                      // SCC Plus chip flag (default 0)
                .sccPlusMode(scc_mode[i])                       // SCC Plus mode flag (default 0)
            );
        end
    endgenerate

endmodule
