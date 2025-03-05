module top
(
   input sclk              /* verilator public */,
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
   input WAITIN            /* verilator public */
);



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
   .track0(),
   .index(),
   .side(),
   .usel(),
   .READY(),
   .TWOSIDE(),

   .int0(),
   .int1(),
   .int2(),
   .int3(),

   .td0(),
   .td1(),
   .td2(),
   .td3(),

   .hmssft(),
   
   .busy(),
   .mfm(),

   .ismode(),

   .sclk(sclk),
   .fclk(fclk),
   .rstn(rstn)
);

endmodule