module opl3 (
    cpu_bus_if.device_mp   cpu_bus,
    device_bus             device_bus,
    input MSX::io_device_t io_device[3],
    output signed [15:0]   sound
);

    assign sound = (io_device[0].enable ? sound_OPL3[0] : '0) +
                   (io_device[1].enable ? sound_OPL3[1] : '0) +
                   (io_device[2].enable ? sound_OPL3[2] : '0);

    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            opl3_enabled <= 3'b111;
        end else if (device_bus.typ == DEV_OPL3 && device_bus.num < 3) begin
            opl3_enabled[device_bus.num] <= device_bus.en;
        end
    end

    wire io_en = cpu_bus.iorq && ~cpu_bus.m1;

    logic signed [15:0] sound_OPL3[0:2];
    logic [2:0] opl3_enabled;
    genvar i;

    generate
        for (i = 0; i < 3; i++) begin : OPL3_INSTANCES
            wire cs_io_active = (cpu_bus.addr[7:0] & io_device[i].mask) == io_device[i].port;
            wire cs_enable = io_device[i].enable && cs_io_active && io_en && opl3_enabled[i];
            wire cs_dev_bus = (device_bus.typ == DEV_OPL3 && device_bus.we && i == device_bus.num);
            jt2413 OPL3_i (
                .clk(cpu_bus.clk),
                .rst(cpu_bus.reset),
                .cen(cpu_bus.clk_en),
                .din(cpu_bus.data),
                .addr(cpu_bus.addr[0]),
                .cs_n(~(cs_enable || cs_dev_bus)),
                .wr_n(~((cpu_bus.wr && cpu_bus.req) || device_bus.we)),
                .snd(sound_OPL3[i]),
                .sample()
            );
        end
    endgenerate

endmodule
