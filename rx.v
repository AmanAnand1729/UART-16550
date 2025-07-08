`timescale 1ns/1ps

module rx(
  input        clk, rst,
  input        baud_tick,    
  input        tick16,       
  input        srx,          
  input  [7:0] lcr,          
  output reg [7:0] rbr,      
  output reg     rbr_full,   
  output reg     frame_err,  
  output reg     parity_err  
);

  
  localparam IDLE=0, START=1, DATA=2, STOP=3;
  reg [1:0]  state;
  reg [3:0]  os_count;     
  reg [2:0]  bit_count;    
  reg [7:0]  shift_reg;    
  reg [1:0]  srx_sync;     
  reg        srx_prev;     

  reg calculated_parity;
  integer j;
  reg rbr_full_d;
  
  wire [3:0] word_len = (lcr[1:0]==2'b11) ? 8 :
                         (lcr[1:0]==2'b10) ? 7 :
                         (lcr[1:0]==2'b01) ? 6 : 5;
  wire parity_en = lcr[3]; // Parity enable bit
  wire even_parity = lcr[4]; // Even/odd parity selection bit
  reg expected_parity_bit_value;
  // Two-stage synchronizer for SRX input (updates on clk)
  always @(posedge clk) begin
    srx_sync <= {srx_sync[0], srx};
    srx_prev <= srx_sync[1]; 
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
        state       <= IDLE;
        os_count    <= 4'd0;
        bit_count   <= 3'd0;
        rbr_full    <= 1'b0;
        rbr_full_d<=1'b0;
        frame_err   <= 1'b0;
        parity_err  <= 1'b0;
        shift_reg   <= 8'd0;
    end else begin
        rbr_full    <= 1'b0; 
        rbr_full_d<=rbr_full;
        frame_err   <= 1'b0; 

        case (state)
            IDLE: begin
                if (srx_sync[1] == 1'b0) begin 
                    state    <= START;
                    os_count <= 4'd0; 
                   
                end
            end

            START: begin
                if (tick16) begin 
                    os_count <= os_count + 1;

                    if (os_count == 8) begin // At mid-point of start bit
                        if (srx_sync[1] == 1'b0) begin 
                            state       <= DATA;
                            os_count    <= 4'd0; 
                            bit_count   <= 3'd0; 
                           
                        end else begin
                            // Framing error: start bit not low
                            frame_err <= 1'b1;
                            state     <= IDLE;
                            
                        end
                    end
                end
            end

            DATA: begin
                if (tick16) begin 
                    os_count <= os_count + 1;

                    if (os_count == 8) begin 
                        shift_reg[bit_count] <= srx_sync[1]; 
                       
                    end

                    if (os_count == 15) begin 
                        if (bit_count == word_len - 1) begin // Check for last data bit (7 for 8N1)
                            state       <= STOP;
                            os_count    <= 4'd0; 
                            
                        end else begin
                            bit_count   <= bit_count + 1; 
                            os_count    <= 4'd0; 
                            
                        end
                    end
                end
            end

            STOP: begin
                if (tick16) begin 
                    os_count <= os_count + 1;

                    if (os_count == 8) begin
                        if (srx_sync[1] != 1'b1) frame_err <= 1'b1; 
                    end

                    if (os_count == 15) begin 
                        rbr_full <= 1'b1; 
                        rbr      <= shift_reg; 
                       
                        state    <= IDLE; 
                        os_count <= 4'd0; 
                    end
                end
            end

            default: state <= IDLE; 
        endcase
    end
end
endmodule
