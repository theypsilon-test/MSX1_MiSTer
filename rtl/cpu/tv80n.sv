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

// Negative-edge based wrapper allows memory wait_n signal to work
// correctly without resorting to asynchronous logic.

`define TV80DELAY

module tv80n (/*AUTOARG*/
    // Outputs
    cpu_bus_if.cpu_mp cpu_bus,
    output            busak_n,
    // Inputs
    input             wait_n, 
    input             int_n, 
    input             nmi_n, 
    input             busrq_n, 
    input       [7:0] di
  );

  parameter Mode = 0;    // 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
  parameter T2Write = 0; // 0 => wr_n active in T3, /=0 => wr_n active in T2
  parameter IOWait  = 1; // 0 => Single cycle I/O, 1 => Std I/O cycle


  reg           mreq_n; 
  reg           iorq_n; 
  reg           rd_n; 
  reg           wr_n; 
  reg           nxt_mreq_n; 
  reg           nxt_iorq_n; 
  reg           nxt_rd_n; 
  reg           nxt_wr_n; 
  
  wire          intcycle_n;
  wire          no_read;
  wire          write;
  wire          iorq;
  wire          m1_n;
  wire          rfsh_n;
  wire          halt_n;
  wire [15:0]   A;
  wire  [7:0]   dout;
  reg [7:0]     di_reg;
  wire [6:0]    mcycle;
  wire [6:0]    tstate;

  tv80_core #(Mode, IOWait) i_tv80_core
    (
     .cen (1),
     .m1_n (m1_n),
     .iorq (iorq),
     .no_read (no_read),
     .write (write),
     .rfsh_n (rfsh_n),
     .halt_n (halt_n),
     .wait_n (wait_n),
     .int_n (int_n),
     .nmi_n (nmi_n),
     .reset_n (~cpu_bus.reset),
     .busrq_n (busrq_n),
     .busak_n (busak_n),
     .clk (cpu_bus.clk_en),
     .IntE (),
     .stop (),
     .A (A),
     .dinst (di),
     .di (di_reg),
     .dout (dout),
     .mc (mcycle),
     .ts (tstate),
     .intcycle_n (intcycle_n)
     );  

  always @*
    begin
      nxt_mreq_n = 1;
      nxt_rd_n   = 1;
      nxt_iorq_n = 1;
      nxt_wr_n   = 1;
      
      if (mcycle[0])
        begin
	  if (tstate[1] || tstate[2])
            begin
	      nxt_rd_n = ~ intcycle_n;
	      nxt_mreq_n = ~ intcycle_n;
	      nxt_iorq_n = intcycle_n;
	    end
        end // if (mcycle[0])          
      else
        begin
	  if ((tstate[1] || tstate[2]) && !no_read && !write)
            begin
	      nxt_rd_n = 1'b0;
	      nxt_iorq_n = ~ iorq;
	      nxt_mreq_n = iorq;
	    end
	  if (T2Write == 0)
            begin                          
	      if (tstate[2] && write)
                begin
		  nxt_wr_n = 1'b0;
		  nxt_iorq_n = ~ iorq;
		  nxt_mreq_n = iorq;
                end
            end
	  else
            begin
	      if ((tstate[1] || (tstate[2] && !wait_n)) && write)
                begin
		  nxt_wr_n = 1'b0;
		  nxt_iorq_n = ~ iorq;
		  nxt_mreq_n = iorq;
		end
	    end // else: !if(T2write == 0)          
	end // else: !if(mcycle[0])
    end // always @ *

  always @(negedge cpu_bus.clk_en)
    begin
      if (cpu_bus.reset)
        begin
	  rd_n   <= `TV80DELAY 1'b1;
	  wr_n   <= `TV80DELAY 1'b1;
	  iorq_n <= `TV80DELAY 1'b1;
	  mreq_n <= `TV80DELAY 1'b1;
        end
      else
        begin
	  rd_n <= `TV80DELAY nxt_rd_n;
	  wr_n <= `TV80DELAY nxt_wr_n;
	  iorq_n <= `TV80DELAY nxt_iorq_n;
	  mreq_n <= `TV80DELAY nxt_mreq_n;
	end // else: !if(!reset_n)
    end // always @ (posedge clk or negedge reset_n)

  always @(posedge cpu_bus.clk_en)
    begin
      if (cpu_bus.reset)
        begin
	  di_reg <= `TV80DELAY 0;
        end
      else
        begin
	  if (tstate[2] && wait_n == 1'b1)
	    di_reg <= `TV80DELAY di;
	end // else: !if(!reset_n)
    end // always @ (posedge clk)

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

endmodule // t80n

