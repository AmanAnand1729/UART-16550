`timescale 1ns/1ps

module rx(
    input        clk, rst,
    input        baud_tick,   
    input        tick16,      
    input        srx,         
    input  [7:0] lcr,         
    output reg [7:0] rbr,               // Still 8-bit output to FIFO
    output reg   rbr_full,    
    output reg   frame_err,   
    output reg   parity_err,
    output       ecc_err_detected,      // NEW: flags for debugging/LSR
    output       ecc_err_corrected      // NEW: flags for debugging/LSR
);

    localparam IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0]  state;
    reg [3:0]  os_count;     
    reg [3:0]  bit_count;       // Expanded to 4 bits
    reg [11:0] shift_reg;       // Expanded to 12 bits
    reg [1:0]  srx_sync;     
    reg        srx_prev;     

    reg calculated_parity;
    integer j;
    reg rbr_full_d;

    // Hamming Decoder wires
    wire [7:0] corrected_data;
    wire [3:0] syndrome;
    
    // Instantiate the Hamming Decoder
    hamming_decoder ecc_dec (
        .code(shift_reg[11:0]),         // 12-bit received code
        .data_out(corrected_data),      // 8-bit corrected data
        .syndrome(syndrome),
        .error_detected(ecc_err_detected),
        .error_corrected(ecc_err_corrected)
    );

    // Word length is forced to 12 because of the (12,8) Hamming code
    wire [3:0] word_len = 4'd12;
    wire parity_en = lcr[3]; 
    wire even_parity = lcr[4]; 
    reg expected_parity_bit_value;

    // Two-stage synchronizer for SRX input
    always @(posedge clk) begin
        srx_sync <= {srx_sync[0], srx};
        srx_prev <= srx_sync[1]; 
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            os_count    <= 4'd0;
            bit_count   <= 4'd0;
            rbr_full    <= 1'b0;
            rbr_full_d  <= 1'b0;
            frame_err   <= 1'b0;
            parity_err  <= 1'b0;
            shift_reg   <= 12'd0;
            rbr         <= 8'd0;
        end else begin
            rbr_full    <= 1'b0; 
            rbr_full_d  <= rbr_full;
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

                        if (os_count == 8) begin // Mid-point of start bit
                            if (srx_sync[1] == 1'b0) begin 
                                state       <= DATA;
                                os_count    <= 4'd0; 
                                bit_count   <= 4'd0; 
                            end else begin
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
                            if (bit_count == word_len - 1) begin // Check for 12th bit
                                state       <= STOP; // Should transition to PARITY if parity_en, simplified here
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
                            // output the CORRECTED 8-bit data instead of the raw shift register
                            rbr      <= corrected_data; 
                            
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
