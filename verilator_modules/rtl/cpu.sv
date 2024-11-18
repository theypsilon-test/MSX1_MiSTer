module cpu
(
    //Interface to verilate
    input        mreq_n /* verilator public */,
    input        iorq_n /* verilator public */,
    input        rd_n /* verilator public */,
    input        wr_n /* verilator public */,
    input        halt_n /* verilator public */,
    input        rfsh_n /* verilator public */,
    input        m1_n /* verilator public */,
    input  [7:0] dout /* verilator public */,
    input [15:0] A /* verilator public */,
    
    //input
    input  [7:0] di /* verilator public */,
    
    //output
    cpu_bus_if.cpu_mp cpu_bus
);

logic iack;
always @(posedge cpu_bus.clk) begin
    if (cpu_bus.reset) iack <= 0;
    else begin
        if (iorq_n  & mreq_n)
            iack <= 0;
        else
            if (req)
                iack <= 1;
    end
end

wire req = ~((iorq_n & mreq_n) | (wr_n & rd_n) | iack);


  assign cpu_bus.mreq = ~mreq_n;
  assign cpu_bus.iorq = ~iorq_n;
  assign cpu_bus.rd = ~rd_n;
  assign cpu_bus.wr = ~wr_n;
  assign cpu_bus.halt = ~halt_n;
  assign cpu_bus.rfsh = ~rfsh_n;
  assign cpu_bus.addr = A;
  assign cpu_bus.data = dout;
  assign cpu_bus.m1  = ~m1_n;
  assign cpu_bus.req = req;

endmodule