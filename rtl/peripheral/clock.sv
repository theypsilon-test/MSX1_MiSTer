module clock
(
   input        clk,
   input        reset,
   clock_bus_if clock_bus
);

reg  [1:0] clkdiv4 =  2'd1;
reg  [2:0] clkdiv6 =  3'd5;
reg [21:0] div     = 22'd2147727;

always @(posedge clk, posedge reset) begin
   if (reset) 
      clkdiv4 <= 2'd1;
   else
      clkdiv4 <= clkdiv4 + 1'd1;
end

always @(posedge clk, posedge reset) begin
   if (reset) 
      clkdiv6 <= 3'd5;
   else    
      if (clkdiv6 == 3'd0) 
         clkdiv6 <= 3'd5;
      else
         clkdiv6 <= clkdiv6 - 1'b1;
end

always @(posedge clk) begin
   if (div == 22'd0)
      div <= 22'd2147727;
   else
      div <= div - 1'd1; 
end

assign clock_bus.clk_sys   = clk;
assign clock_bus.ce_10m7_p = clkdiv4[0];
assign clock_bus.ce_10m7_n = ~clkdiv4[0];
assign clock_bus.ce_5m39_p = &clkdiv4;
assign clock_bus.ce_5m39_n = ~clkdiv4[1] & clkdiv4[0];
assign clock_bus.ce_3m58_p = clkdiv6 == 3'd5;
assign clock_bus.ce_3m58_n = clkdiv6 == 3'd2;
assign clock_bus.ce_10hz   = div == 22'd0;

endmodule
