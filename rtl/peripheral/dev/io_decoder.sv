module io_decoder (
    input  logic [7:0]           cpu_addr,     // Address from CPU bus
    input  MSX::io_device_t      io_device[16],// Array of IO devices
    output logic [2:0]           enable,       // Enable signals for devices
    output logic [7:0]           params[3],    // ID enabled device
    output logic [26:0]          memory[3],    // ID enabled device
    output logic [7:0]           memory_size[3]    // ID enabled device
);
    parameter DEV_NAME;

    // Internal registers to accumulate values
    logic [2:0] temp_enable;
    /* verilator lint_off LATCH */
    always_comb begin
        // Initialize to zero
        temp_enable = 3'b000;

        // Iterate over each IO device
        for (int i = 0; i < 16; i++) begin
            if ((cpu_addr & io_device[i].mask) == io_device[i].port && io_device[i].id == DEV_NAME) begin
                params[io_device[i].num] = io_device[i].param;
                memory[io_device[i].num] = io_device[i].memory;
                memory_size[io_device[i].num] = io_device[i].memory_size;
                temp_enable |= (3'b001 << io_device[i].num);         // Accumulate enable signals
            end
        end
        
        // Assign the accumulated values to the outputs
        enable = temp_enable;
    end
endmodule
