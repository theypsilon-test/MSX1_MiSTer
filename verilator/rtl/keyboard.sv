module keyboard
(
   input         clk,
   input         reset,
   input  [10:0] ps2_key,
   input   [3:0] kb_row,
   output  [7:0] kb_data,
   input   [8:0] kbd_addr,
   input   [7:0] kbd_din,
   input         kbd_we,
   input         kbd_request
);

endmodule;