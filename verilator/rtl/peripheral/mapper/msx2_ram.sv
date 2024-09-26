/* verilator tracing_off */
module mapper_msx2_ram (
    cpu_bus        cpu_bus,         // Interface for CPU communication
    block_info     block_info,      // Struct containing mapper configuration and parameters
    mapper_out     out,             // Interface for mapper output
    device_bus     device_out,      // Interface for device control
    input [7:0]    data_to_mapper
);
    assign out.ram_cs = '0;
    assign out.addr = {27{1'b1}};
    assign out.rnw = '1;
    assign device_out.typ = DEV_NONE;
endmodule

module msx2_ram (
    cpu_bus                 cpu_bus,         // Interface for CPU communication
    device_bus              device_bus,      // Interface for device control
    input  [2:0]            dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
    input  MSX::io_device_t io_device[16],   // Array of IO devices with port and mask info
    output                  output_rq,
    output            [7:0] data,
    output            [7:0] data_to_mapper
);

assign data_to_mapper = '1;
assign data = '1;
assign output_rq = '0;

endmodule