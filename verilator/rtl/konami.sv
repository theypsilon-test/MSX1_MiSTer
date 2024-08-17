/*verilator tracing_off*/
module cart_konami
(
    input            clk,
    input            reset,
    input     [24:0] rom_size,
    input     [15:0] cpu_addr,
    input      [7:0] din,
    input            cpu_mreq,
    input            cpu_wr,
    input            cs,
    input            cart_num,
    output           mem_unmaped,
    output    [24:0] mem_addr
);

assign mem_addr    = '1;
assign mem_unmaped = cs;

endmodule