//
// TV80 8-Bit Microprocessor Core
// Based on the VHDL T80 core by Daniel Wallner (jesus@opencores.org)
//
// Copyright (c) 2004 Guy Hutchison (ghutchis@opencores.org)
//
// Permission is hereby granted, free of charge, to any person obtaining a 
// copy of this software and associated documentation files (the "Software"), 
// to deal in the Software without restriction, including without limitation 
// the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the 
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module tv80_reg (/*AUTOARG*/
  // Outputs
  DOBH, DOAL, DOCL, DOBL, DOCH, DOAH, cpu_regs,
  // Inputs
  AddrC, AddrA, AddrB, DIH, DIL, clk, CEN, WEH, WEL
  );
    input  [2:0] AddrC;
    output [7:0] DOBH;
    input  [2:0] AddrA;
    input  [2:0] AddrB;
    input  [7:0] DIH;
    output [7:0] DOAL;
    output [7:0] DOCL;
    input  [7:0] DIL;
    output [7:0] DOBL;
    output [7:0] DOCH;
    output [7:0] DOAH;
    input  clk, CEN, WEH, WEL;
    cpu_regs_if cpu_regs;

  reg [7:0] RegsH [0:7];
  reg [7:0] RegsL [0:7];

  always @(posedge clk)
    begin
      if (CEN)
        begin
          if (WEH) RegsH[AddrA] <= DIH;
          if (WEL) RegsL[AddrA] <= DIL;
        end
    end
          
  assign DOAH = RegsH[AddrA];
  assign DOAL = RegsL[AddrA];
  assign DOBH = RegsH[AddrB];
  assign DOBL = RegsL[AddrB];
  assign DOCH = RegsH[AddrC];
  assign DOCL = RegsL[AddrC];

  // break out ram bits for waveform debug
// synopsys translate_off
  wire [7:0] B = RegsH[0];
  wire [7:0] BP = RegsH[4];
  wire [7:0] C = RegsL[0];
  wire [7:0] CP = RegsL[4];
  wire [7:0] D = RegsH[1];
  wire [7:0] DP = RegsH[5];
  wire [7:0] E = RegsL[1];
  wire [7:0] EP = RegsL[5];
  wire [7:0] H = RegsH[2];
  wire [7:0] HP = RegsH[6];
  wire [7:0] L = RegsL[2];
  wire [7:0] LP = RegsL[6];

  wire [15:0] IX = { RegsH[3], RegsL[3] };
  wire [15:0] IY = { RegsH[7], RegsL[7] };
// synopsys translate_on
  
    assign cpu_regs.BC  = {RegsH[0],RegsL[0]};
    assign cpu_regs.DE  = {RegsH[1],RegsL[1]};
    assign cpu_regs.HL  = {RegsH[2],RegsL[2]};
    assign cpu_regs.IX  = {RegsH[3],RegsL[3]};
    assign cpu_regs.BC2 = {RegsH[4],RegsL[4]};
    assign cpu_regs.DE2 = {RegsH[5],RegsL[5]};
    assign cpu_regs.HL2 = {RegsH[6],RegsL[6]};
    assign cpu_regs.IY = {RegsH[7],RegsL[7]};
    
endmodule

