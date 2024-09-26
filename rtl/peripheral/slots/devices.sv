/*verilator tracing_off*/
module devices (
    cpu_bus         cpu_bus,            // Interface for CPU communication
    device_bus      device_bus,         // Interface for device control
    sd_bus          sd_bus,
    sd_bus_control  sd_bus_control,
    image_info      image_info,    
    input     [2:0] dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
    input MSX::io_device_t   io_device[16],  // Array of IO devices with port and mask info
    output signed [15:0] sound,          // Combined sound output
    output [7:0]    data,
    output          output_rq,
    output    [7:0] data_to_mapper
);
    // Combine sound outputs from the devices
    assign sound = opl3_sound + scc_sound ;
    assign data = scc_data & vy0010_data & msx2_ram_data;
    assign output_rq = scc_output_rq | vy0010_output_rq | msx2_ram_output_rq;
    assign data_to_mapper = msx2_ram_data_to_mapper;

    /*verilator tracing_off*/
    wire signed [15:0] opl3_sound;
    opl3 OPL3
    (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .dev_enable(dev_enable),
        .io_device(io_device),
        .sound(opl3_sound)
    );

    wire [7:0] scc_data;
    wire       scc_output_rq;
    wire signed [15:0] scc_sound;
    scc SCC
    (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .dev_enable(dev_enable),
        .io_device(io_device),
        .sound(scc_sound),
        .data(scc_data),
        .output_rq(scc_output_rq)
    );
    /*verilator tracing_off*/
    wire [7:0] msx2_ram_data_to_mapper;
    wire [7:0] msx2_ram_data;
    wire       msx2_ram_output_rq;
    msx2_ram msx2_ram
    (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .dev_enable(dev_enable),
        .io_device(io_device),
        .data(msx2_ram_data),
        .output_rq(msx2_ram_output_rq),
        .data_to_mapper(msx2_ram_data_to_mapper)
    );

/*verilator tracing_off*/
    wire [7:0] vy0010_data;
    wire       vy0010_output_rq;
    vy0010 vy0010
    (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .sd_bus(sd_bus),
        .sd_bus_control(sd_bus_control),
        .image_info(image_info),
        .data(vy0010_data),
        .output_rq(vy0010_output_rq)
    );

endmodule


