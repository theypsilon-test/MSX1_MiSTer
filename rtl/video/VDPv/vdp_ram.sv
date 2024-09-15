module RAM_v (
  input  logic [7:0] ADR,
  input  logic CLK,
  input  logic WE,
  input  logic [7:0] DBO,
  output logic [7:0] DBI
);

  logic [7:0] blkram [255:0];
  logic [7:0] iADR;

  always_ff @(posedge CLK) begin
    if (WE) begin
      blkram[ADR] <= DBO;
    end
    iADR <= ADR;
  end

  assign DBI = blkram[iADR];

endmodule