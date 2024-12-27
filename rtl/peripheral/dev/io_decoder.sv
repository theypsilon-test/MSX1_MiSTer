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
    logic [7:0] temp_params[3];
    logic [26:0] temp_memory[3];
    logic [7:0] temp_memory_size[3];

    always_comb begin
        // Initialize to zero
        temp_enable = 3'b000;
        temp_params = '{default: 8'b0};
        temp_memory = '{default: 27'b0};
        temp_memory_size = '{default: 8'b0};

        // Iterate over each IO device
        for (int i = 0; i < 16; i++) begin
            if ((cpu_addr & io_device[i].mask) == io_device[i].port && io_device[i].id == DEV_NAME) begin
                temp_params[io_device[i].num] = io_device[i].param;
                temp_memory[io_device[i].num] = io_device[i].memory;
                temp_memory_size[io_device[i].num] = io_device[i].memory_size;
                temp_enable |= (3'b001 << io_device[i].num);         // Accumulate enable signals
            end
        end
    end

    // Assign the accumulated values to the outputs
    assign enable = temp_enable;
    assign params = temp_params;
    assign memory = temp_memory;
    assign memory_size = temp_memory_size;
endmodule
