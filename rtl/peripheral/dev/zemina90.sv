module zemina90 (
    clock_bus_if            clock_bus,                              // Interface for clock
    cpu_bus_if.device_mp    cpu_bus,                                // Interface for CPU communication
    device_bus              device_bus,                             // Interface for device control
    input  [2:0]            dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
    input  MSX::io_device_t io_device[16],                          // Array of IO devices with port and mask info
    output            [7:0] data_to_mapper
);

    // Signals
    logic [2:0] mapper_io;
    logic [7:0] size;
    logic [7:0] data_out[0:2], data_to_mapper_ar[0:2];
    wire       io_en = cpu_bus.iorq && ~cpu_bus.m1;

    // Instantiate IO decoder to generate enable signals and parameters
    io_decoder #(.DEV_NAME(DEV_ZEMINA90)) msx2_mem_mapper_decoder (
        .cpu_addr(cpu_bus.addr[7:0]),
        .io_device(io_device),
        .enable(mapper_io),
        .param(size)
    );

    // Generate request and output signals
    assign data_to_mapper = device_bus.typ == DEV_ZEMINA90 ? data_to_mapper_ar[device_bus.num] : 8'hFF;

    // Generate MSX2 Memory Mapper Device Instances
    genvar i;
    generate
        for (i = 0; i < 3; i++) begin : zemina90_dev_INSTANCES
            zemina90_dev zemina90_dev_i (
                .clk(clock_bus.clk_sys),
                .clk_en(clock_bus.ce_3m58_p),
                .reset(clock_bus.reset),
                .data(cpu_bus.data),
                .wr(mapper_io[i] && io_en && cpu_bus.wr),  // IO write
                .data_to_mapper(data_to_mapper_ar[i])
            );
        end
    endgenerate

endmodule

module zemina90_dev (
    input              reset,
    input              clk,
    input              clk_en,
    input              wr,
    input       [15:0] addr,
    input        [7:0] data,
    output logic [7:0] data_to_mapper
);
    logic [7:0] mem_seg[0:3];
    logic [7:0] page;

    assign page = ({2'b00, data[5:0]}) << 1;

    // Memory segment handling with read and write operations
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_seg[0] <= 8'd0;
            mem_seg[1] <= 8'd1;
            mem_seg[2] <= 8'd0;
            mem_seg[3] <= 8'd1;
        end else if (wr && clk_en) begin
            $display("Write IO Zemina 90 addr %x value %x store page %x ", {data[7:6], 2'b00}, {2'b00,data[5:4]}, page );
            case(data[7:6])
            2'b00, 2'b01: begin  // 0x00 && 0x40
                mem_seg[0] <= page;
                mem_seg[1] <= page + 1'd1;
                mem_seg[2] <= page;
                mem_seg[3] <= page + 1'd1;
            end 
            2'b10: begin  // 0x80
                mem_seg[0] <= (page & ~8'd2);
                mem_seg[1] <= (page & ~8'd2) + 1'd1;
                mem_seg[2] <= (page | 8'd2 );
                mem_seg[3] <= (page | 8'd2 ) + 1'd1;
            end
            2'b11: begin // 0xC0
                mem_seg[0] <= page;
                mem_seg[1] <= page + 1'd1;
                mem_seg[2] <= page + 1'd1;
                mem_seg[3] <= page;
            end
            endcase
        end
    end

    // Output logic with optional bitwise operation based on size
    logic [3:0] addr_rq;
    assign addr_rq = addr[15:13] - 3'd2;
    assign data_to_mapper = mem_seg[addr_rq[1:0]];

endmodule