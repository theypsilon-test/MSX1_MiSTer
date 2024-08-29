module subslot (
    input               clk, 
    input               reset, 
    input               cpu_mreq,
    input               cpu_wr,
    input               cpu_rd,
    input         [7:0] cpu_data,
    input        [15:0] cpu_addr,
    input         [1:0] active_slot,
    input         [3:0] expander_enable,
    output        [7:0] data,
    output        [1:0] active_subslot,
    output              cs
);

logic [7:0] mapper_slot[3:0];  // Deklarace mapper_slot pro 4 sloty

wire mapper_cs = (cpu_addr == 16'hFFFF) & expander_enable[active_slot] & cpu_mreq;
wire mapper_wr = mapper_cs & cpu_wr;
wire mapper_rd = mapper_cs & cpu_rd;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Inicializace mapper_slot při resetu
        mapper_slot[0] <= 8'h00;
        mapper_slot[1] <= 8'h00;
        mapper_slot[2] <= 8'h00;
        mapper_slot[3] <= 8'h00;
    end else if (mapper_wr) begin
        // Zápis do aktuálně aktivního slotu
        mapper_slot[active_slot] <= cpu_data;
        //$display("EXPANDER CHANGE: SLOT %x value %x", active_slot, cpu_data);
    end
end

wire [1:0] block = cpu_addr[15:14];

assign data = mapper_rd ? ~mapper_slot[active_slot] : 8'hFF;
assign active_subslot = mapper_slot[active_slot][(3'd2 * block) +: 2];
assign cs = mapper_cs;
endmodule
