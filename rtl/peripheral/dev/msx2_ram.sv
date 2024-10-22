/*verilator tracing_off*/
module msx2_ram (
    clock_bus_if            clock_bus,       // Interface for clock
    cpu_bus_if.device_mp    cpu_bus,         // Interface for CPU communication
    device_bus              device_bus,      // Interface for device control
    input  [2:0]            dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
    input  MSX::io_device_t io_device[16],   // Array of IO devices with port and mask info
    output                  output_rq,
    output            [7:0] data,
    output            [7:0] data_to_mapper
);

    // Signals
    logic [2:0] mapper_io;
    logic [7:0] size;
    logic [7:0] data_out[0:2], data_to_mapper_ar[0:2];
    wire       io_en = cpu_bus.iorq && ~cpu_bus.m1;

    // Instantiate IO decoder to generate enable signals and parameters
    io_decoder #(.DEV_NAME(DEV_MSX2_RAM)) msx2_mem_mapper_decoder (
        .cpu_addr(cpu_bus.addr[7:0]),
        .io_device(io_device),
        .enable(mapper_io),
        .param(size)
    );

    // Generate request and output signals
    assign output_rq = io_en && cpu_bus.rd && |mapper_io;
    assign data      = data_out[0] & data_out[1] & data_out[2];
    assign data_to_mapper = device_bus.typ == DEV_MSX2_RAM ? data_to_mapper_ar[device_bus.num] : 8'hFF;

    // Generate MSX2 Memory Mapper Device Instances
    genvar i;
    generate
        for (i = 0; i < 3; i++) begin : msx2_ram_dev_INSTANCES
            msx2_ram_dev msx2_ram_dev_i (
                .clk(clock_bus.clk_sys),
                .reset(clock_bus.reset),
                .data(cpu_bus.data),
                .addr(cpu_bus.addr),
                .oe(mapper_io[i] && io_en && cpu_bus.rd),  // IO read
                .wr(mapper_io[i] && io_en && cpu_bus.wr),  // IO write
                .size(size),
                .q(data_out[i]),
                .data_to_mapper(data_to_mapper_ar[i])
            );
        end
    endgenerate

endmodule

module msx2_ram_dev (
    input              reset,
    input              clk,
    input              oe,
    input              wr,
    input       [15:0] addr,
    input        [7:0] data,
    output       [7:0] q,
    input        [7:0] size,
    output logic [7:0] data_to_mapper
);
    logic [7:0] mem_seg[0:3];

    // Memory segment handling with read and write operations
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_seg[0] <= 8'd0; // Reset segment FC
            mem_seg[1] <= 8'd0; // Reset segment FD
            mem_seg[2] <= 8'd0; // Reset segment FE
            mem_seg[3] <= 8'd0; // Reset segment FF
        end else if (wr) begin
            mem_seg[addr[1:0]] <= data & (size -1'b1); // Write data to selected segment
        end
    end

    // Output logic with optional bitwise operation based on size
    assign q = oe ? (mem_seg[addr[1:0]] | (~(size -1'b1))) : 8'hFF;
    assign data_to_mapper = mem_seg[addr[15:14]];
endmodule
