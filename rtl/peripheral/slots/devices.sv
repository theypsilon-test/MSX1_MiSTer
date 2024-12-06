module devices (
    clock_bus_if.base_mp    clock_bus,                              // Clock interface
    cpu_bus_if.device_mp    cpu_bus,                                // CPU bus interface
    device_bus              device_bus,                             // Device control bus interface
    sd_bus                  sd_bus,                                 // SD bus interface
    sd_bus_control          sd_bus_control,                         // SD bus control interface
    image_info              image_info,                             // Image information
    input             [2:0] dev_enable[0:(1 << $bits(device_t))-1], // Enable signals
    input             [7:0] dev_params[0:(1 << $bits(device_t))-1][3], //Params devices
    input MSX::io_device_t  io_device[16],                          // Array of IO devices
    output    signed [15:0] sound,                                  // Combined audio output
    output            [7:0] data,                                   // Combined data output
    output                  data_oe_rq,                             // Priorite data
    output            [7:0] data_to_mapper,                         // Data output to mapper
    output           [26:0] ram_addr,
    output                  ram_cs
);

    // Výstupy kombinující jednotlivé zařízení
    assign sound = opl3_sound + scc_sound;
    assign data = scc_data & wd2793_data & msx2_ram_data;
    assign data_oe_rq = wd2793_data_oe_rq;
    assign data_to_mapper = msx2_ram_data_to_mapper & latch_port_data_to_mapper;

    assign ram_cs = kanji_ram_cs;
    assign ram_addr = kanji_ram_addr;

    // Definice instancí zařízení s výstupy pro propojení
    wire signed [15:0] opl3_sound;
    opl3 opl3 (
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
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .dev_enable(dev_enable),
        .io_device(io_device),
        .sound(scc_sound),
        .data(scc_data)
    );

    wire [7:0] msx2_ram_data_to_mapper;
    wire [7:0] msx2_ram_data;
    msx2_ram msx2_ram (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .dev_enable(dev_enable),
        .io_device(io_device),
        .data(msx2_ram_data),
        .data_to_mapper(msx2_ram_data_to_mapper)
    );

    wire [7:0] latch_port_data_to_mapper;
    latch_port latch_port (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .dev_enable(dev_enable),
        .io_device(io_device),
        .data_to_mapper(latch_port_data_to_mapper)
    );

    wire [7:0] wd2793_data;
    wire wd2793_data_oe_rq;
    WD2793 WD2793 (
        .cpu_bus(cpu_bus),
        .device_bus(device_bus),
        .sd_bus(sd_bus),
        .sd_bus_control(sd_bus_control),
        .image_info(image_info),
        .data(wd2793_data),
        .data_oe_rq(wd2793_data_oe_rq),
        .param(dev_params[DEV_WD2793][0])
    );

    wire [26:0] kanji_ram_addr;
    wire        kanji_ram_cs;
    kanji kanji (
        .cpu_bus(cpu_bus),
        .io_device(io_device),
        .ram_cs(kanji_ram_cs),
        .ram_addr(kanji_ram_addr)
    );

endmodule
