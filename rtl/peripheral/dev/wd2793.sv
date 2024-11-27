module WD2793
(
   cpu_bus_if.device_mp cpu_bus,            // Interface for CPU communication
   device_bus           device_bus,         // Interface for device control
   sd_bus               sd_bus,             // Data from SD
   sd_bus_control       sd_bus_control,     // Control SD
   image_info           image_info,
   output         [7:0] data,
   output               data_oe_rq,         // Priorite data 
   input          [7:0] param               // 00 - Philips, 01 - National
);

typedef enum logic [1:0] {DRIVE_NONE, DRIVE_A, DRIVE_B} drive_t;

wire cs = (device_bus.typ == DEV_WD2793) && (device_bus.num == 0); // Only first instance

logic image_mounted = 1'b0;
logic layout = 1'b0;
logic [7:0] philips_sideReg, philips_driveReg;

always @(posedge cpu_bus.clk) begin
   if (image_info.mounted) begin
      image_mounted <= (image_info.size != 0);
      layout <= (image_info.size > 'h5A000) ? 1'b0 : 1'b1;
   end
end

wire area_philips   = (cpu_bus.addr[13:3] == 11'b11111111111) && param == 8'h00;
wire area_national  = (cpu_bus.addr[13:7] ==  7'b1111111) && param == 8'h01;
wire area_device    = area_philips || area_national;
wire device_cs      = cs && area_device && cpu_bus.mreq;

wire wdcs           = device_cs && cpu_bus.addr[2] == 0; // addr 0 - 3

logic motor, side;
drive_t drive;

always @(posedge cpu_bus.clk) begin
   if (cpu_bus.reset) begin
      philips_sideReg  <= 8'd0;
      philips_driveReg <= 8'd0;
      drive <= DRIVE_A;
      side  <= 0;
      motor <= 0;
   end else begin
      if (cpu_bus.wr && cpu_bus.req && cs) begin
         if (area_philips) begin
            if (cpu_bus.addr[2:0] == 3'd4) begin
               philips_sideReg  <= cpu_bus.data;
               side               <= cpu_bus.data[0];
            end
            if (cpu_bus.addr[2:0] == 3'd5) begin 
               philips_driveReg <= cpu_bus.data;
               motor              <=cpu_bus.data[7];
               case(cpu_bus.data[1:0])
                  0, 2: drive <= DRIVE_A;
                  1:    drive <= DRIVE_B;
                  3:    drive <= DRIVE_NONE;
               endcase
            end
         end else begin
            if (area_national) begin
               if (cpu_bus.addr[2] == 1) begin
                  case(cpu_bus.data[1:0])
                     1:       drive <= DRIVE_A;
                     2:       drive <= DRIVE_B;
                     default: drive <= DRIVE_NONE;
                  endcase
               side  <= cpu_bus.data[2];
               motor <= cpu_bus.data[3];
               end
            end
         end
      end
   end
end

always_comb begin
   data = 8'hFF;     // výchozí hodnota pro data
   data_oe_rq = 0;
   if (cpu_bus.rd && device_cs) begin
      if (cpu_bus.addr[2] == 0) begin
         data = d_from_wd17;
         data_oe_rq = 1;;
      end else begin
         if (area_philips) begin
            case(cpu_bus.addr[1:0])
               0: begin data = philips_sideReg; data_oe_rq = 1; end
               1: begin data = philips_driveReg & 8'hFB; data_oe_rq = 1; end  //TODO changed bit
               2: ;
               3: begin data = {~drq, ~intrq, 6'b111111}; data_oe_rq = 1; end
            endcase
         end else begin
            if (area_national) begin
               data = {intrq, ~drq, 6'b111111};
               data_oe_rq = 1;
            end
         end
      end
   end
end

wire fdd_ready = image_mounted && motor && drive == DRIVE_A;

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
   .side(side),
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
