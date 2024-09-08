module io_decoder (
    input  logic [7:0]           cpu_addr,     // Address from CPU bus
    input  MSX::io_device_t      io_device[16],// Array of IO devices
    output logic [2:0]           enable        // Enable signals for devices
);
    parameter DEV_NAME;

    // Generate enable signal based on matching CPU address and IO device information
    assign enable = 
                      ((cpu_addr & io_device[0].mask) == io_device[0].port && io_device[0].id == DEV_NAME ? (3'b001 << io_device[0].num) : 3'b000) |
                      ((cpu_addr & io_device[1].mask) == io_device[1].port && io_device[1].id == DEV_NAME ? (3'b001 << io_device[1].num) : 3'b000) |
                      ((cpu_addr & io_device[2].mask) == io_device[2].port && io_device[2].id == DEV_NAME ? (3'b001 << io_device[2].num) : 3'b000) |
                      ((cpu_addr & io_device[3].mask) == io_device[3].port && io_device[3].id == DEV_NAME ? (3'b001 << io_device[3].num) : 3'b000) |
                      ((cpu_addr & io_device[4].mask) == io_device[4].port && io_device[4].id == DEV_NAME ? (3'b001 << io_device[4].num) : 3'b000) |
                      ((cpu_addr & io_device[5].mask) == io_device[5].port && io_device[5].id == DEV_NAME ? (3'b001 << io_device[5].num) : 3'b000) |
                      ((cpu_addr & io_device[6].mask) == io_device[6].port && io_device[6].id == DEV_NAME ? (3'b001 << io_device[6].num) : 3'b000) |
                      ((cpu_addr & io_device[7].mask) == io_device[7].port && io_device[7].id == DEV_NAME ? (3'b001 << io_device[7].num) : 3'b000) |
                      ((cpu_addr & io_device[8].mask) == io_device[8].port && io_device[8].id == DEV_NAME ? (3'b001 << io_device[8].num) : 3'b000) |
                      ((cpu_addr & io_device[9].mask) == io_device[9].port && io_device[9].id == DEV_NAME ? (3'b001 << io_device[9].num) : 3'b000) |
                      ((cpu_addr & io_device[10].mask) == io_device[10].port && io_device[10].id == DEV_NAME ? (3'b001 << io_device[10].num) : 3'b000) |
                      ((cpu_addr & io_device[11].mask) == io_device[11].port && io_device[11].id == DEV_NAME ? (3'b001 << io_device[11].num) : 3'b000) |
                      ((cpu_addr & io_device[12].mask) == io_device[12].port && io_device[12].id == DEV_NAME ? (3'b001 << io_device[12].num) : 3'b000) |
                      ((cpu_addr & io_device[13].mask) == io_device[13].port && io_device[13].id == DEV_NAME ? (3'b001 << io_device[13].num) : 3'b000) |
                      ((cpu_addr & io_device[14].mask) == io_device[14].port && io_device[14].id == DEV_NAME ? (3'b001 << io_device[14].num) : 3'b000) |
                      ((cpu_addr & io_device[15].mask) == io_device[15].port && io_device[15].id == DEV_NAME ? (3'b001 << io_device[15].num) : 3'b000);

endmodule