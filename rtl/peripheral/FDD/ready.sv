module ready (
    input  logic        clk,
    input  logic        reset,
    input  logic        USEL,
    input  logic  [1:0] motor_run,
    output logic        READYn,
    output logic        sides,
    output logic        WPROTn,

    input logic   [1:0] img_mounted,
    input logic   [1:0] img_readonly,
    input logic  [63:0] img_size[2]
);

    logic [1:0] reg_sides;
    logic [1:0] reg_wprotect;
    logic [1:0] reg_enable;
    logic [1:0] last_mounted;
    
    initial begin
        reg_sides = '{'0,'0};
        reg_wprotect = '{'0,'0};
        reg_enable = '{'0,'0};
    end

    genvar i;
    generate
        for (i=0; i < 2; i++) begin : IMAGE_REDY_I
            always_ff @(posedge clk) begin    
                last_mounted[i] <= img_mounted[i];
                
                if (img_mounted[i] && ~last_mounted[i]) begin
                    if (img_size[i] == 737280) begin
                        reg_sides[i]    <= 1;
                        reg_wprotect[i] <= img_readonly[i];
                        reg_enable[i]   <= 1;
                        $display("MOUNT DD  %t",  $time);
                    end else 
                    if (img_size[i] == 368640) begin
                        reg_sides[i]    <= 0;
                        reg_wprotect[i] <= img_readonly[i];
                        reg_enable[i]   <= 1;
                        $display("MOUNT SD  %t",  $time);
                    end else begin
                        reg_sides[i]    <= 0;
                        reg_wprotect[i] <= 1;
                        reg_enable[i]   <= 0;
                        $display("UNMOUNT  %t",  $time);
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
