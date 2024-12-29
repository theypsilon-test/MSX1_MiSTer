module scc (
    cpu_bus_if.device_mp   cpu_bus,
    device_bus             device_bus,
    input MSX::io_device_t io_device[3],
    output   signed [15:0] sound,
    output           [7:0] data
);

    assign sound = (io_device[0].enable ? {sound_SCC[0][14], sound_SCC[0]} : '0) +
                   (io_device[1].enable ? {sound_SCC[1][14], sound_SCC[1]} : '0);

    always @(posedge cpu_bus.clk) begin
        if (cpu_bus.reset) begin
            scc_mode    <= 2'b00;
            scc_plus    <= 2'b00;
        end else if (device_bus.typ == DEV_SCC && device_bus.num < 2) begin
            scc_mode[device_bus.num[0]]    <= device_bus.mode;
            scc_plus[device_bus.num[0]]    <= device_bus.param;
        end
    end

    wire signed [14:0] sound_SCC[0:1];
    wire [7:0] data_SCC[2];
    logic [1:0] scc_mode;
    logic [1:0] scc_plus;

    wire cs = device_bus.typ == DEV_SCC && device_bus.en;

    assign data = cs && cpu_bus.rd ? data_SCC[device_bus.num[0]] : 8'hFF;

    genvar i;
    generate
        for (i = 0; i < 2; i++) begin : SCC_INSTANCES
            scc_wave scc_wave_i (
                .clk(cpu_bus.clk),
                .clkena(cpu_bus.clk_en),
                .reset(cpu_bus.reset),
                .req(cs && device_bus.num == i),
                .ack(),
                .wrt(cpu_bus.wr && cpu_bus.req),
                .adr(cpu_bus.addr[7:0]),
                .dbo(cpu_bus.data),
                .dbi(data_SCC[i]),
                .wave(sound_SCC[i]),
                .sccPlusChip(scc_plus[i]),
                .sccPlusMode(scc_mode[i])
            );
        end
    endgenerate

endmodule
