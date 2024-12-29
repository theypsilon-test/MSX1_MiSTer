module dev_rtc (
    cpu_bus_if.device_mp    cpu_bus,
    clock_bus_if.base_mp    clock_bus,
    input  MSX::io_device_t io_device[3],
    input            [64:0] rtc_time,
    output            [7:0] data
);

assign data = '1;

endmodule