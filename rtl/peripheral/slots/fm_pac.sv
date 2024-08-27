/*verilator tracing_on*/
module mapper_fm_pac
(
   input                clk,
   input                reset,
   input                cpu_mreq,
   input                cpu_rd,
   input                cpu_wr,
   input          [7:0] cpu_data,
   input         [15:0] cpu_addr,
   input  mapper_typ_t  mapper,
   input                mapper_id,
   output         [7:0] data,
   output        [26:0] mem_addr,
   output               mem_rnw,
   output               ram_cs,
   output               sram_cs

//   output         [7:0] mapper_dout,  
//   input                cs,
//   input                cart_num,
//   output               sram_we,
//   output               sram_cs,
//   output               mem_unmaped,
   
//   output         [1:0] opll_wr, 
//   output         [1:0] opll_io_enable
);
   
// Signály a logika pro mapování paměti
wire cs, mapped, mapper_en, sramEnable;


assign mapped       = cpu_addr[15:14] == 2'b01;          // Adresa je platná pouze 0x4000 - 0x7FFF
assign mapper_en    = (mapper == MAPPER_FMPAC);
assign cs           = mapper_en & cpu_mreq;
assign sramEnable = {magicHi[mapper_id],magicLo[mapper_id]} == 16'h694D;

assign data = mapper_en & cpu_addr[13:0] == 14'h3FF6              ? enable[mapper_id]            :
              mapper_en & cpu_addr[13:0] == 14'h3FF7              ? {6'b000000, bank[mapper_id]} :
              mapper_en & cpu_addr[13:0] == 14'h1FFE & sramEnable ? magicLo[mapper_id]           :
              mapper_en & cpu_addr[13:0] == 14'h1FFF & sramEnable ? magicHi[mapper_id]           :
                                                                    8'hFF                        ;

logic [7:0] enable[2];
logic [1:0] bank[2];
logic [7:0] magicLo[2];
logic [7:0] magicHi[2];
logic       last_mreq;

initial begin
   opll_wr        = '0;
   enable         = '{default: '0};
   bank           = '{default: '0};
   magicLo        = '{default: '0};
   magicHi        = '{default: '0};
end

//assign opll_io_enable = enable[0];         // Zápis OPL
logic         opll_wr;                       // Write to OPL


always @(posedge clk) begin
   if (reset) begin
      enable  <= '{default: '0};
      bank    <= '{default: '0};
      magicLo <= '{default: '0};
      magicHi <= '{default: '0};
   end else begin
      opll_wr <= 1'b0;
      if (mapper_en & cpu_wr & cpu_mreq) begin
         case (cpu_addr[13:0]) 
            14'h1FFE:
               if (~enable[mapper_id][4]) 
                  magicLo[mapper_id]   <= cpu_data;
            14'h1FFF:
               if (~enable[mapper_id][4]) 
                  magicHi[mapper_id]   <= cpu_data;
            14'h3FF4,
            14'h3FF5: begin
               opll_wr <= 1'b1;
            end
            14'h3FF6: begin
               enable[mapper_id] <= cpu_data & 8'h11;
               if (enable[mapper_id][4]) begin
                  magicLo[mapper_id] <= 0;
                  magicHi[mapper_id] <= 0;
               end
            end
            14'h3FF7: begin
               bank[mapper_id] <=cpu_data[1:0];
            end
            default: ;
         endcase
      end
   end
   last_mreq <= cpu_mreq & (cpu_rd | cpu_wr);
end

wire        sram_en    = sramEnable & ~cpu_addr[13] & ((~last_mreq & cpu_wr) | cpu_mreq & cpu_rd);
wire [26:0] sram_addr  = 27'(cpu_addr[12:0]);
wire [26:0] ram_addr   = 27'({bank[mapper_id], cpu_addr[13:0]});

assign sram_cs    = cs & sram_en;
assign ram_cs     = cs & ~sram_en & cpu_rd & mapped;
assign mem_rnw    = ~(sram_cs & cpu_wr);
assign mem_addr   = cs ? (sram_cs ? sram_addr : ram_addr) : {27{1'b1}};

endmodule