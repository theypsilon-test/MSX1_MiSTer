module ready #(TIMEOUT = 30, DELAY = 3)
(
    input  logic        clk,
    input  logic        reset,
    input  logic  [1:0] USEL,
    input  logic  [3:0] motor_run,
    output logic        READYn,
    output logic        sides,
    output logic        WPROTn,


    input logic       [3:0] img_mounted,
    input logic             img_readonly,
    input logic      [63:0] img_size
);

    logic [3:0] reg_sides;
    logic [3:0] reg_wprotect;
    logic [3:0] reg_enable;
    logic [3:0] last_mounted;
    
    genvar i;
    generate
        for (i=0; i < 4; i++) begin
            always_ff @(posedge clk or posedge reset) begin
                if (reset) begin
                    reg_sides[i] <= 0;
                    reg_wprotect[i] <= 0;
                    reg_enable[i] <= 0;
                end else begin
                    
                    last_mounted[i] <= img_mounted[i];
                    
                    if (img_mounted[i] && ~last_mounted[i]) begin
                        if (img_size == 737280) begin
                            reg_sides[i]    <= 1;
                            reg_wprotect[i] <= img_readonly;
                            reg_enable[i]   <= 1;
                        end else 
                        if (img_size == 368640) begin
                            reg_sides[i]    <= 0;
                            reg_wprotect[i] <= img_readonly;
                            reg_enable[i]   <= 1;
                        end else begin
                            reg_sides[i]    <= 0;
                            reg_wprotect[i] <= 1;
                            reg_enable[i]   <= 0;
                        end
                    end
                end
            end
        end
    endgenerate

    always_comb begin
        sides    = reg_sides[USEL];
        WPROTn   = !reg_wprotect[USEL];
        READYn   = !(reg_enable[USEL] && motor_run[USEL]);
    end

endmodule
