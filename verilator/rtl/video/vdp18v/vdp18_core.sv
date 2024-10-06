module vdp18_core #(
  parameter integer compat_rgb_g = 0
)(
  // Global Interface
  input logic        clk_i,
  input logic        clk_en_10m7_i,
  input logic        reset_n_i,
  // CPU Interface
  input logic        csr_n_i,
  input logic        csw_n_i,
  input logic        mode_i,
  output logic       int_n_o,
  input logic [7:0]  cd_i,
  output logic [7:0] cd_o,
  // VRAM Interface
  output logic       vram_we_o,
  output logic [13:0] vram_a_o,
  output logic [7:0] vram_d_o,
  input logic [7:0]  vram_d_i,
  // Video Interface
  input logic        border_i,
  input logic        is_pal_i,
  output logic [3:0] col_o,
  output logic [7:0] rgb_r_o,
  output logic [7:0] rgb_g_o,
  output logic [7:0] rgb_b_o,
  output logic       hsync_n_o,
  output logic       vsync_n_o,
  output logic       blank_n_o,
  output logic       hblank_o,
  output logic       vblank_o,
  output logic       comp_sync_n_o,
  output logic       ce_pix
);

endmodule
