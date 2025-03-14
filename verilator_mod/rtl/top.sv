module top
(
//   input sclk              /* verilator public */,
   input fclk              /* verilator public */,
   input rstn              /* verilator public */,
   input RDn               /* verilator public */,
   input WRn               /* verilator public */,
   input CSn               /* verilator public */,
   input A0                /* verilator public */,
   input [7:0] WDAT        /* verilator public */,
   output [7:0] RDAT       /* verilator public */,
   output DATOE            /* verilator public */,
   input DACKn             /* verilator public */,
   output DRQ              /* verilator public */,
   input  TC               /* verilator public */,
   output INTn             /* verilator public */,
   input WAITIN            /* verilator public */,

   // Mister IMAGE
   input   [5:0] img_mounted    /* verilator public */,
	input         img_readonly   /* verilator public */,
   input  [63:0] img_size       /* verilator public */,

   //SD block level access
   output logic [31:0] sd_lba[0:5]      /* verilator public */,
   output  [5:0] sd_blk_cnt[0:5]  /* verilator public */,
   output  logic [5:0] sd_rd          /* verilator public */,
   output  [5:0] sd_wr          /* verilator public */,
   input   [5:0] sd_ack         /* verilator public */,
   
   // SD byte level access. Signals for 2-PORT altsyncram.
   input  [13:0] sd_buff_addr   /* verilator public */,
   input   [7:0] sd_buff_dout   /* verilator public */,
   output  [7:0] sd_buff_din[0:5] /* verilator public */,
   input         sd_buff_wr     /* verilator public */,

   // FDD TEST signals
   input   [1:0] USEL     /* verilator public */,
   input         MOTORn   /* verilator public */,
   input         STEPn    /* verilator public */,
   input         SDIRn    /* verilator public */,
   input         SIDEn    /* verilator public */,

   // WD1793 TEST signals
   input         ce       /* verilator public */,
   input         io_en    /* verilator public */,
   input         rd       /* verilator public */,
   input         wr       /* verilator public */,  
   input  [1:0]  addr     /* verilator public */,
   input  [7:0]  din      /* verilator public */,
   output [7:0]  dout     /* verilator public */,
   output        drq      /* verilator public */,
   output        intrq    /* verilator public */,
   output        busy     /* verilator public */,
   output        wp       /* verilator public */,
   input         side     /* verilator public */,
   input         ready    /* verilator public */
);
/*
initial begin
   sd_lba = '{32'd0, 32'd0, 32'd0, 32'd0, 32'd0, 32'd0};
   //sd_rd = 6'b0;
end

logic [3:0] cnt = 4'd1;
logic last_mount = 0;
always_ff @(posedge fclk) begin
   if (!last_mount && img_mounted[3]) begin
      cnt <= '1;
   end else begin
      if (img_mounted[3]) begin
         if (cnt > '0) begin
            cnt <= cnt - 1'b1;
         end else begin
            sd_lba[3] <= 32'd1;
            sd_rd[3] <= '1;
         end
      end
   end
   last_mount <= img_mounted[3];
end
*/
/*
tc8566af tc8566af (
   .RDn(RDn),
   .WRn(WRn),
   .CSn(CSn),
   .A0(A0),
   .WDAT(WDAT),
   .RDAT(RDAT),
   .DATOE(DATOE),
   .DACKn(DACKn),
   .DRQ(DRQ),
   .TC(TC),
   .INTn(INTn),
   .WAITIN(WAITIN),

   .WREN(),
   .WRBIT(),
   .RDBIT(),
   .STEP(),
   .SDIR(),
   .WPRT(),
   .track0(1),
   .index(1),
   .side(),
   .usel(),
   .READY(1),
   .TWOSIDE(),

   .int0(),
   .int1(),
   .int2(),
   .int3(),

   .td0(),
   .td1(),
   .td2(),
   .td3(),

   .hmssft(hmssft),
   
   .busy(),
   .mfm(),

   .ismode(),

   .sclk(sclk),
   .fclk(fclk),
   .rstn(rstn)
);
*/
logic msclk;
sftgen mss (
        .len(10),
        .sft(msclk),
        .clk(fclk),
        .rstn(rstn)
);
logic sclk;
sftgen s (
        .len(10),
        .sft(sclk),
        .clk(fclk),
        .rstn(rstn)
);

fdd #() fdd(
   .clk(fclk),
   .msclk(msclk),
   .reset(~rstn),
   .USEL(USEL),
   .MOTORn(MOTORn),
   .STEPn(STEPn),
   .SDIRn(SDIRn), 
   .SIDEn(SIDEn),
   .img_mounted(img_mounted[3:0]),
   .img_readonly(img_readonly),
   .img_size(img_size),
   .sd_lba(sd_lba[0:3]),
   .sd_blk_cnt(sd_blk_cnt[0:3]),
   .sd_rd(sd_rd[3:0]),
   .sd_wr(sd_wr[3:0]),
   .sd_ack(sd_ack[3:0]),
   .sd_buff_addr(sd_buff_addr),
   .sd_buff_dout(sd_buff_dout),
   .sd_buff_din(sd_buff_din[0:3]),
   .sd_buff_wr(sd_buff_wr)

);

wd1793 wd1793 (
   .clk_sys(fclk),
   .ce(),
   .reset(),
   .io_en(),
   .rd(),
   .wr(),
   .addr(),
   .din(),
   .dout(),
   .drq(),
   .intrq(),
   .busy(),
   .wp(),
   .side(),
   .ready()
);

/*
logic hmssft;
FDtiming #(.sysclk(21477)) FDD (
    .drv0sel(),    // 0:300rpm 1:360rpm
    .drv1sel(),
    .drv0sele(),   // 1:speed selectable
    .drv1sele(),

    .drv0hd(),
    .drv0hdi(),    // IBM 1.44MB format
    .drv1hd(),
    .drv1hdi(),    // IBM 1.44MB format

    .drv0hds(), //out
    .drv1hds(), //out

    .drv0int(), //out
    .drv1int(), //out

    .hmssft(hmssft),

    .clk(fclk),
    .rstn(rstn)
);
*/


endmodule