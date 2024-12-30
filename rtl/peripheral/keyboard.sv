module keyboard
(
   input                  clk,
   input                  reset,
   input           [10:0] ps2_key,
   input            [3:0] kb_row,
   output           [7:0] kb_data,
   input MSX::kb_memory_t upload_memory
);

wire [3:0] row;

logic [7:0] row_state [16] = '{default:8'hFF};
logic [8:0] key_decode;
logic down, change;
logic [7:0] pos;

assign kb_data    = row_state[kb_row];
assign key_decode = ps2_key[8:0];

logic [10:0] old_key = 11'd0;
always @(posedge clk) begin
   change     <= 1'b0;
   old_key <= ps2_key;
   if (old_key != ps2_key) begin
      down       <= ps2_key[9];
      change     <= 1'b1;
   end
end

assign row = map_key[7:4];
assign pos = 8'b1 << map_key[3:0];

always @(posedge clk) begin
   if (change) begin
      row_state[row] <= down ?  row_state[row] & ~pos : row_state[row] | pos;
   end
end

wire [7:0] map_key;
spram #(.addr_width(9), .mem_name("KBD"), .mem_init_file("kbd.mif")) kbd_ram 
(
   .clock(clk),
   .address(upload_memory.rq ? upload_memory.addr : key_decode),
   .data(upload_memory.data),
   .q(map_key),
   .wren(upload_memory.we)
);

endmodule