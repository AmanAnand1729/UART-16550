`timescale 1ns / 1ps

module baud_rate_generator (
    input          clk,          
    input          rst,          
    input          load_divisor, 
    input  [7:0]   dll,          
    input  [7:0]   dlm,          
    output reg     baud_tick,    
    output reg     tick16        
);

    // Internal registers to hold divisor and counter values
    reg [15:0] divisor_reg;       
    reg [15:0] count_16x;         
    reg [3:0]  baud_tick_counter; 
    
    wire [15:0] divisor_value = {dlm, dll};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            divisor_reg       <= 16'd651; // Default divisor for 9600 baud (100MHz clock)
            count_16x         <= 16'd0;
            baud_tick_counter <= 4'd0;
            baud_tick         <= 1'b0;
            tick16            <= 1'b0;
        end else begin
            if (load_divisor) begin
                divisor_reg       <= divisor_value;
                count_16x         <= 16'd0;
                baud_tick_counter <= 4'd0;
                baud_tick         <= 1'b0;
                tick16            <= 1'b0;
            end else begin
                baud_tick <= 1'b0;
                tick16    <= 1'b0;
                
                if (count_16x == divisor_reg - 1) begin
                    count_16x <= 16'd0;    
                    tick16    <= 1'b1;     
                    if (baud_tick_counter == 4'd15) begin
                        baud_tick_counter <= 4'd0;    
                        baud_tick         <= 1'b1;    
                    end else begin
                        baud_tick_counter <= baud_tick_counter + 1; 
                    end
                end else begin
                    count_16x <= count_16x + 1; 
                end
            end
        end
    end

endmodule