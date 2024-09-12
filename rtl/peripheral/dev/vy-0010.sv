/*verilator tracing_on*/
module vy0010
(
   cpu_bus         cpu_bus,            // Interface for CPU communication
   device_bus      device_bus,         // Interface for device control
   sd_bus          sd_bus,             // Data from SD
   sd_bus_control  sd_bus_control,     // Control SD
   image_info      image_info,
   output   [7:0]  data,
   output          output_rq
);

wire cs = device_bus.typ == DEV_VY0010 && device_bus.num == 0;      //Only first instance


logic image_mounted = 1'b0;
logic layout = 1'b0;
logic [7:0] sideReg, driveReg;

always @(posedge cpu_bus.clk) begin
   if (image_info.mounted) begin
      image_mounted <= image_info.size != 0;
      layout <= image_info.size > 'h5A000 ? 1'b0 : 1'b1;
   end
end

wire wdcs     = cs & cpu_bus.addr[13:2] == 12'b111111111110; 
wire ck1      = cs & cpu_bus.addr[13:0] == 14'h3ffc; 
wire ck2      = cs & cpu_bus.addr[13:0] == 14'h3ffd; 
wire nu       = cs & cpu_bus.addr[13:0] == 14'h3ffe;
wire status   = cs & cpu_bus.addr[13:0] == 14'h3fff; 

always @(posedge cpu_bus.reset, posedge cpu_bus.clk) begin
   if (cpu_bus.clk)
      sideReg <= 8'd0;
   else 
      if (ck1 & cpu_bus.wr)
         sideReg     <= cpu_bus.data;
end

always @(posedge cpu_bus.reset, posedge cpu_bus.clk) begin
   if (cpu_bus.reset) begin
      driveReg    <= 8'd0;
   end else 
      if (ck2 & cpu_bus.wr) begin
         driveReg <= cpu_bus.data;
      end
end

wire fdd_ready = image_mounted & driveReg[7] & ~driveReg[0];

assign {output_rq, data } = status   ? {cpu_bus.rd, ~drq, ~intrq, 6'b111111}  :
                            ck1      ? {cpu_bus.rd, sideReg}                  :
                            ck2      ? {cpu_bus.rd, driveReg & 8'hFB }        :
                            wdcs     ? {cpu_bus.rd, d_from_wd17}              :
                            nu       ? {cpu_bus.rd, 8'hFF}                    :
                                       9'h0FF;
wire [7:0] d_from_wd17;
wire drq, intrq;
wd1793 #(.RWMODE(1), .EDSK(0)) fdc1
(
   .clk_sys(cpu_bus.clk),
   .ce(cpu_bus.clk_en),
   .reset(cpu_bus.reset),
   .io_en(wdcs),
   .rd(cpu_bus.rd),
   .wr(cpu_bus.wr),
   .addr(cpu_bus.addr[1:0]),
   .din(cpu_bus.data),
   .dout(d_from_wd17),
   .drq(drq),
   .intrq(intrq),
   .ready(fdd_ready),
   .layout(layout),
   .size_code(3'h2),
   .side(sideReg[0]),
   .img_mounted(image_info.mounted),
   .wp(image_info.readonly),
   .img_size(image_info.size[19:0]),
   .sd_lba(sd_bus_control.sd_lba),
   .sd_rd(sd_bus_control.rd),
   .sd_wr(sd_bus_control.wr),
   .sd_ack(sd_bus.ack),
   .sd_buff_addr(sd_bus.buff_addr[8:0]),
   .sd_buff_dout(sd_bus.buff_data),
   .sd_buff_din(sd_bus_control.buff_data),
   .sd_buff_wr(sd_bus.buff_wr),
   .input_active(1'b0),
   .input_addr(20'h0),
   .input_data(8'h0),
   .input_wr(1'b0),
   .buff_din(8'h0)
);

endmodule
