module sftgen (
    input  logic              clk,
    input  logic              rstn,
    input  int unsigned       len,
    output logic              sft
);

    int unsigned count;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            count <= 0;
            sft   <= 0;
        end else begin
            if (count > 1) begin
                count <= count - 1;
                sft   <= 0;
            end else begin
                sft   <= 1;
                count <= len;
            end
        end
    end
endmodule
