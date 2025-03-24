// WD2793 device
//
// Copyright (c) 2024-2025 Molekula
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Redistributions in synthesized form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the distribution.
//
// * Neither the name of the author nor the names of other contributors may
//   be used to endorse or promote products derived from this software without
//   specific prior written agreement from the author.
//
// * License is granted for non-commercial use only.  A fee may not be charged
//   for redistributions as source code or in synthesized/hardware form without
//   specific prior written agreement from the author.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//

module dev_WD2793
(
   cpu_bus_if.device_mp cpu_bus,
   clock_bus_if.base_mp clock_bus,
   device_bus           device_bus,
   input  MSX::io_device_t io_device[3],
   FDD_if.FDC_mp            FDD_bus,
   sd_bus               sd_bus,
   sd_bus_control       sd_bus_control,
   image_info           image_info,
   output         [7:0] data,
   output               data_oe_rq
);

typedef enum logic [1:0] {DRIVE_NONE, DRIVE_A, DRIVE_B} drive_t;

wire cs = (device_bus.typ == DEV_WD2793) && (device_bus.num == 0);

logic image_mounted = 1'b0;
logic layout = 1'b0;
logic [7:0] philips_sideReg, philips_driveReg;

always @(posedge cpu_bus.clk) begin
   if (image_info.mounted) begin
      image_mounted <= (image_info.size != 0);
      layout <= (image_info.size > 'h5A000) ? 1'b0 : 1'b1;
   end
end

wire area_philips   = (cpu_bus.addr[13:3] == 11'b11111111111) && io_device[0].param[1:0] == 2'h0;
wire area_national  = (cpu_bus.addr[13:7] ==  7'b1111111) && io_device[0].param[1:0] == 2'h1;
wire area_device    = area_philips || area_national;
wire device_cs      = cs && area_device && cpu_bus.mreq;

wire wdcs           = device_cs && cpu_bus.addr[2] == 0;

logic motor, side;
drive_t drive;


assign FDD_bus.USEL   = 0;                //TODO zatim jeden image
assign FDD_bus.MOTORn = ~(motor && drive == DRIVE_A);
assign FDD_bus.SIDEn  = ~side;

wire [1:0] dbg_status = image_info.enable ? {drq_old, intrq_old} : {drq, intrq};

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
               side             <= cpu_bus.data[0];
               //$display("WRITE DEV SIDEREG  %X  (%d,%d) %t", cpu_bus.data, dbg_status[0], dbg_status[1], $time);
            end
            if (cpu_bus.addr[2:0] == 3'd5) begin 
               philips_driveReg <= cpu_bus.data;
               motor              <=cpu_bus.data[7];
               //$display("WRITE DEV DRIVEREG %X  (%d,%d) %t", cpu_bus.data, dbg_status[0], dbg_status[1], $time);
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

logic last_data_oe_crc;
always_comb begin
   data = 8'hFF;
   data_oe_rq = 0;
  
   if (cpu_bus.rd && device_cs) begin
      if (cpu_bus.addr[2] == 0) begin
         data = image_info.enable ? d_from_wd17_old : d_from_wd17;
         data_oe_rq = 1;
      end else begin
         if (area_philips) begin
            case(cpu_bus.addr[1:0])
               0: begin data = philips_sideReg; data_oe_rq = 1; end
               1: begin data = philips_driveReg & 8'hFB; data_oe_rq = 1; end
               2: ;
               3: begin data = image_info.enable ?  {~drq_old, ~intrq_old, 6'b111111} : {~drq, ~intrq, 6'b111111}; data_oe_rq = 1; end
            endcase
         end else begin
            if (area_national) begin
               data = image_info.enable ? {intrq_old, ~drq_old, 6'b111111} : {intrq, ~drq, 6'b111111};
               data_oe_rq = 1;
            end
         end
      end
   end
end
/*
logic last_data_oe_rq;
logic [7:0] last_data;
logic [2:0] last_addr;
logic [1:0] last_dbg_status;
always_ff @(posedge cpu_bus.clk) begin
   last_data_oe_rq <= data_oe_rq;
   last_data <= data;
   last_addr <= cpu_bus.addr[2:0];
   last_dbg_status <= dbg_status;
   if (last_data_oe_rq && !data_oe_rq) begin
      case(last_addr)
         0: $display("READ  FDC STATUS   %X  (%d,%d) %t", last_data, last_dbg_status[0], last_dbg_status[1], $time);
         1: $display("READ  FDC TRACK    %X  (%d,%d) %t", last_data, last_dbg_status[0], last_dbg_status[1], $time);
         2: $display("READ  FDC SECTOR   %X  (%d,%d) %t", last_data, last_dbg_status[0], last_dbg_status[1], $time);
         3: $display("READ  FDC DATA     %X  (%d,%d) %t", last_data, last_dbg_status[0], last_dbg_status[1], $time);
         4: $display("READ  DEV SIDEREG  %X  (%d,%d) %t", last_data, last_dbg_status[0], last_dbg_status[1], $time);
         5: $display("READ  DEV DRIVEREG %X  (%d,%d) %t", last_data, last_dbg_status[0], last_dbg_status[1], $time);
         6: ;
         7: $display("READ  DEV STATUS   %X  (%d,%d) %t", last_data, last_dbg_status[0], last_dbg_status[1], $time);
      endcase
   end

   if (wdcs && cpu_bus.wr && cpu_bus.req && cs) begin
      case(cpu_bus.addr[1:0])
         0: $display("WRITE FDC COMMAND  %X  (%d,%d) %t", cpu_bus.data, dbg_status[0], dbg_status[1], $time);
         1: $display("WRITE FDC TRACK    %X  (%d,%d) %t", cpu_bus.data, dbg_status[0], dbg_status[1], $time);
         2: $display("WRITE FDC SECTOR   %X  (%d,%d) %t", cpu_bus.data, dbg_status[0], dbg_status[1], $time);
         3: $display("WRITE FDC DATA     %X  (%d,%d) %t", cpu_bus.data, dbg_status[0], dbg_status[1], $time);  
      endcase
   end
end
*/
logic [15:0] crc;
logic fdc_we;

assign fdc_we = data_oe_rq && (image_info.enable ? busy : dbg_busy) && wdcs && (image_info.enable ? drq_old : drq);
/*
crc #(.CRC_WIDTH(16)) crc1
(
   .clk(cpu_bus.clk),
   .valid(image_info.enable ? !intrq_old : !intrq),
   .we(fdc_we & ~last_data_oe_crc) ,
   .data_in(image_info.enable ? d_from_wd17_old : d_from_wd17),
   .crc(crc )
);


logic last;
always @(posedge cpu_bus.clk) begin
   last_data_oe_crc <= fdc_we;
   last <= image_info.enable ? intrq_old : intrq;
   if (last && !(image_info.enable ? intrq_old : intrq))
      $display("CRC %X %t", crc, $time);
end
*/
wire fdd_ready = image_mounted && motor && drive == DRIVE_A;

wire [7:0] d_from_wd17_old;
wire drq_old, intrq_old, busy, dbg_busy;

wd1793 wd2793_iold
(
   .clk_sys(cpu_bus.clk),
   .ce(clock_bus.ce_3m58_n),
   .reset(cpu_bus.reset),
   .io_en(wdcs),
   .rd(cpu_bus.rd),
   .wr(cpu_bus.wr),
   .addr(cpu_bus.addr[1:0]),
   .din(cpu_bus.data),
   .dout(d_from_wd17_old),
   .drq(drq_old),
   .intrq(intrq_old),
   .ready(fdd_ready),
   .layout(layout),
   .busy(busy),
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

wire [7:0] d_from_wd17;
wire drq, intrq;
wd279x #(.WD279_57(0)) wd2793_i
(
   .clk(cpu_bus.clk),
   .msclk(clock_bus.ce_1k),
   .MRn(~cpu_bus.reset),
   .CSn(~wdcs),
   .REn(~cpu_bus.rd),
   .WEn(~cpu_bus.wr),
   .A(cpu_bus.addr[1:0]),
   .DIN(cpu_bus.data),
   .DOUT(d_from_wd17),
   .DRQ(drq),
   .INTRQ(intrq),
   
   //FDD
   .STEPn(FDD_bus.STEPn),
   .SDIRn(FDD_bus.SDIRn),
   .INDEXn(FDD_bus.INDEXn),
   .TRK00n(FDD_bus.TRACK0n),
   .READYn(FDD_bus.READYn),
   .WPROTn(FDD_bus.WPROTn),
   .SSO(),  //Pouze WD2795/7
   //FDD helper
   .fdd_data(FDD_bus.data),
   .fdd_bclk(FDD_bus.bclk),
   .sec_id(FDD_bus.sec_id),
   .data_valid(FDD_bus.data_valid),
   .dbg_busy(dbg_busy)

   // .ready(fdd_ready),               //TODO ziskat z FDD
   // .layout(layout),
   // .size_code(3'h2),
   /*
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
   .buff_din(8'h0)*/
);

endmodule
