module devices (
    clock_bus_if            clock_bus,                              // Clock interface
    cpu_bus_if.device_mp    cpu_bus,                                // CPU bus interface
    device_bus              device_bus,                             // Device control bus interface
    sd_bus                  sd_bus,                                 // SD bus interface
    sd_bus_control          sd_bus_control,                         // SD bus control interface
    image_info              image_info,                             // Image information
    input [2:0]             dev_enable[0:(1 << $bits(device_t))-1], // Enable signals
    input MSX::io_device_t  io_device[16],                          // Array of IO devices
    output    signed [15:0] sound,                                  // Combined audio output
    output            [7:0] data,                                   // Combined data output
    output                  output_rq,                              // Combined output request
    output            [7:0] data_to_mapper                          // Data output to mapper
);

    // Výstupy kombinující jednotlivé zařízení
    assign sound = opl3_sound + scc_sound;
    assign data = scc_data & vy0010_data & msx2_ram_data;
    assign output_rq = scc_output_rq | vy0010_output_rq | msx2_ram_output_rq;
    assign data_to_mapper = msx2_ram_data_to_mapper & zemina_data_to_mapper;

    // Definice instancí zařízení s výstupy pro propojení
    wire signed [15:0] opl3_sound;
    opl3 opl3 (
        .clock_bus(clock_bus),
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .dev_enable(dev_enable),
        .io_device(io_device),
        .sound(opl3_sound)
    );

    wire [7:0] scc_data;
    wire       scc_output_rq;
    wire signed [15:0] scc_sound;
    scc scc (
        .clock_bus(clock_bus),
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .dev_enable(dev_enable),
        .io_device(io_device),
        .sound(scc_sound),
        .data(scc_data),
        .output_rq(scc_output_rq)
    );

    wire [7:0] msx2_ram_data_to_mapper;
    wire [7:0] msx2_ram_data;
    wire       msx2_ram_output_rq;
    msx2_ram msx2_ram (
        .clock_bus(clock_bus),
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .dev_enable(dev_enable),
        .io_device(io_device),
        .data(msx2_ram_data),
        .output_rq(msx2_ram_output_rq),
        .data_to_mapper(msx2_ram_data_to_mapper)
    );

    wire [7:0] zemina_data_to_mapper;
    zemina90 zemina90 (
        .clock_bus(clock_bus),
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .dev_enable(dev_enable),
        .io_device(io_device),
        .data_to_mapper(zemina_data_to_mapper)
    );

    wire [7:0] vy0010_data;
    wire       vy0010_output_rq;
    vy0010 vy0010 (
        .clock_bus(clock_bus),
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .sd_bus(sd_bus),
        .sd_bus_control(sd_bus_control),
        .image_info(image_info),
        .data(vy0010_data),
        .output_rq(vy0010_output_rq)
    );

endmodule
