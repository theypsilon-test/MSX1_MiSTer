module tv80n (/*AUTOARG*/
  // Outputs
  m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n, halt_n, busak_n, A, dout,
  // Inputs
  reset_n, clk, wait_n, int_n, nmi_n, busrq_n, di
  );

  parameter Mode = 0;    // 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
  parameter T2Write = 0; // 0 => wr_n active in T3, /=0 => wr_n active in T2
  parameter IOWait  = 1; // 0 => Single cycle I/O, 1 => Std I/O cycle


  input         reset_n; 
  input         clk; 
  input         wait_n; 
  input         int_n; 
  input         nmi_n; 
  input         busrq_n; 
  output        m1_n; 
  output        mreq_n; 
  output        iorq_n; 
  output        rd_n; 
  output        wr_n; 
  output        rfsh_n; 
  output        halt_n; 
  output        busak_n; 
  output [15:0] A;
  input [7:0]   di;
  output [7:0]  dout;

endmodule

