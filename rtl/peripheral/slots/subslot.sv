module subslot (
    cpu_bus_if.device_mp    cpu_bus,        // Interface for CPU communication
    input             [1:0] active_slot,    // Currently active slot
    input             [3:0] expander_enable,// Enable signals for the expander
    output            [7:0] data,           // Data output
    output            [1:0] active_subslot, // Currently active subslot
    output                  output_rq       // Chip select signal
);

    // Array to store mapper slot data for 4 slots
    logic [7:0] mapper_slot[3:0];

    // Chip select is active when the address is 0xFFFF, the expander is enabled for the active slot, and there's a memory request
    wire mapper_cs = (cpu_bus.addr == 16'hFFFF) & expander_enable[active_slot] & cpu_bus.mreq;
    
    // Write enable is active when chip select and write request are active
    wire mapper_wr = mapper_cs & cpu_bus.wr;
    
    // Read enable is active when chip select and read request are active
    wire mapper_rd = mapper_cs & cpu_bus.rd;

    // On clock or reset, update the mapper_slot data
    always @(posedge cpu_bus.clk or posedge cpu_bus.reset) begin
        if (cpu_bus.reset) begin
            // Initialize mapper_slot array on reset
            mapper_slot[0] <= 8'h00;
            mapper_slot[1] <= 8'h00;
            mapper_slot[2] <= 8'h00;
            mapper_slot[3] <= 8'h00;
        end else if (mapper_wr) begin
            // Write to the currently active slot
            mapper_slot[active_slot] <= cpu_bus.data;
            //$display("EXPANDER CHANGE: SLOT %x value %x", active_slot, cpu_data);
        end
    end

    // Block selection based on the address (2 bits representing blocks of memory)
    wire [1:0] block = cpu_bus.addr[15:14];

    // If a read is requested, return the inverted value from the active slot, otherwise return 0xFF
    assign data = mapper_rd ? ~mapper_slot[active_slot] : 8'hFF;

    // Select the active subslot based on the block and the current mapper_slot value
    assign active_subslot = mapper_slot[active_slot][(3'd2 * block) +: 2];

    // Chip select output signal
    assign output_rq = mapper_rd;

endmodule
