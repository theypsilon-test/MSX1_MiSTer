module kanji
(
   cpu_bus_if.device_mp    cpu_bus,                                // Interface for CPU communication
   input  [2:0]            dev_enable[0:(1 << $bits(device_t))-1], // Enable signals for each device
   input  MSX::io_device_t io_device[16],                          // Array of IO devices with port and mask info
   output                  ram_cs,
   output           [26:0] ram_addr
);

   logic [2:0] enable_io;
   wire       io_en = cpu_bus.iorq && ~cpu_bus.m1;

   wire  [7:0] params[3];
   wire [26:0] memory[3];
   wire  [7:0] memory_size[3];
   
   // Instantiate IO decoder to generate enable signals and parameters
   io_decoder #(.DEV_NAME(DEV_KANJI)) kanji_decoder (
      .cpu_addr(cpu_bus.addr[7:0]),
      .io_device(io_device),
      .enable(enable_io),
      .params(params),
      .memory(memory),
      .memory_size(memory_size)
   );

   wire hangul = params[0][0];
   wire lascom = params[0][1];

   kanji_dev kanji_dev (
      .clk(cpu_bus.clk),
      .reset(cpu_bus.reset),
      .data(cpu_bus.data),
      .cpu_addr(cpu_bus.addr[1:0]),
      .ram_base(memory[0]),
      .ram_size(memory_size[0]),
      .req(cpu_bus.req),
      .wr(enable_io[0] && io_en && cpu_bus.wr), // IO write  
      .rd(enable_io[0] && io_en && cpu_bus.rd),                // IO read  
      .hangul(hangul),
      .lascom(lascom),
      .ram_addr(ram_addr),
      .ram_cs(ram_cs)
   );

endmodule 

module kanji_dev (
    input              clk,
    input              reset,
    input        [7:0] data,
    input        [1:0] cpu_addr,
    input       [26:0] ram_base,
    input        [7:0] ram_size,
    input              req,
    input              wr,   
    input              rd,
    input              hangul,
    input              lascom,
    output      [26:0] ram_addr,
    output             ram_cs
);  


   logic [26:0] addr1, addr2, addr;
   logic ram_en;

   assign ram_addr = (ram_cs ? ram_base + addr : '1);
   assign ram_cs   = rd && ram_en;

   wire [6:0] hangul_data = hangul ? data[6:0] : {1'b0,data[5:0]};
   
   always @(posedge clk) begin
      ram_en <= 0;
      
      if (reset) begin
         addr1 <= 27'h00000;
         addr2 <= 27'h20000;
      end else begin
         if (req) begin
            if (wr) begin
               case (cpu_addr)
                  2'd0: addr1 <= (addr1 & 27'h1f800) | (27'(data[5:0]) << 5 );
                  2'd1: addr1 <= (addr1 & 27'h007e0) | (27'(data[5:0]) << 11);
                  2'd2: addr2 <= (addr2 & 27'h3f800) | (27'(hangul_data) << 5 );
                  2'd3: addr2 <= (addr2 & 27'h207e0) | (27'(data[5:0]) << 11);
               endcase
            end
            if (rd) begin 
               ram_en <= 0;
               case (cpu_addr)
                  2'd0: ;
                  2'd1: begin
                     addr <= addr1 &  ({5'b0, ram_size,14'd0} - 27'd1);
                     ram_en <= 1;
                     addr1 <= (addr1 & ~27'h1f) | ((addr1 + 27'd1) & 27'h1f);
                  end
                  2'd2: ;
                  2'd3: begin
                     if (ram_size == 8'h10) begin
                           addr <= addr2;
                           ram_en <= 1;
                     end                    
                     addr2 <= (addr2 & ~27'h1f) | ((addr2 + 27'd1) & 27'h1f);
                  end
               endcase
            end
         end
      end
   end

endmodule