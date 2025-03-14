module index #(RPM = 300)
(
    input  logic        clk,
    input  logic        msclk,  //clk at 1ms
    input  logic        sclk,   //clk at 1s
    input  logic        reset,
    input  logic  [1:0] USEL,
    input  logic        MOTOR,
    output logic  [3:0] motor
);
    logic [5:0] motor_timeout[3:0];     // MAX 64 s
    logic [2:0] motor_delay[3:0];       // MAX 8 ms

    genvar i;
    generate
        for (i=0; i < 4; i++) begin
            always_ff @(posedge clk or posedge reset) begin
                if (reset) begin
                    motor_timeout[i] <= '0;
                    motor_delay[i] <= DELAY;
                end else begin
                    
                    if (sclk && motor_timeout[i] > 0) begin
                        motor_timeout[i] <= motor_timeout[i] - 1;
                    end

                    if ( USEL == i) begin                    
                        motor_timeout[i] <= MOTOR ? TIMEOUT : '0;
                        motor_delay[i] <= MOTOR ? motor_delay[i] : DELAY;
                    end

                    if (msclk && motor_delay[i] > 0 && motor_timeout[i] > 0) begin
                        motor_delay[i] <= motor_delay[i] - 1;
                    end
                end
            end
        
            always_comb begin
                motor[i] = motor_delay[i] == 0 && motor_timeout[i] != 0;
            end 
       
        end
    endgenerate

endmodule
