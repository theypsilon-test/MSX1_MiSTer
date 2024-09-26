module io_decoder (
    input  logic [7:0]           cpu_addr,     // Address from CPU bus
    input  MSX::io_device_t      io_device[16],// Array of IO devices
    output logic [2:0]           enable,       // Enable signals for devices
    output logic [7:0]           param         // ID enabled device
);
    parameter DEV_NAME;

    // Internal registers to accumulate values
    logic [2:0] temp_enable;
    logic [7:0] temp_param;
    
    always_comb begin
        // Initialize to zero
        temp_enable = 3'b000;
        temp_param = 8'b0;

        // Iterate over each IO device
        for (int i = 0; i < 16; i++) begin
            if ((cpu_addr & io_device[i].mask) == io_device[i].port && io_device[i].id == DEV_NAME) begin
                temp_param |= io_device[i].param;                    // Accumulate param values
                temp_enable |= (3'b001 << io_device[i].num);         // Accumulate enable signals
            end
        end
        
        // Assign the accumulated values to the outputs
        enable = temp_enable;
        param = temp_param;
    end
endmodule
