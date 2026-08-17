`timescale 1ns/1ps

module hamming_decoder (

    input  [12:1] code,          // received 12-bit Hamming code
    output reg [7:0] data_out,   // corrected 8-bit data
    output reg [3:0] syndrome,   // error position (0 = no error)
    output reg error_detected,   // high if any error exists
    output reg error_corrected   // high if single-bit error corrected

);

    integer i, j;

    reg [12:1] corrected;

    always @(*) begin
        // Initialize
        corrected       = code;
        syndrome        = 4'b0000;
        error_detected  = 1'b0;
        error_corrected = 1'b0;

        // ------------------------------------------------
        // Syndrome calculation
        // Each parity bit checks positions where its bit is 1
        // ------------------------------------------------

        for(i = 1; i <= 12; i = i + 1) begin

            // We include ALL bits (including parity bits)
            // because syndrome is computed from full codeword

            for(j = 0; j < 4; j = j + 1) begin

                // If j-th bit of index is 1 → contributes to parity check
                if((i >> j) & 1) begin
                    syndrome[j] = syndrome[j] ^ code[i];
                end

            end
        end

        // ------------------------------------------------
        // Error detection
        // ------------------------------------------------

        if(syndrome != 4'b0000) begin
            error_detected = 1'b1;

            // ------------------------------------------------
            // Correct single-bit error
            // syndrome value directly gives error position
            // ------------------------------------------------

            corrected[syndrome] = ~corrected[syndrome];

            error_corrected = 1'b1;
        end

        // ------------------------------------------------
        // Extract original 8-bit data
        // (same mapping as encoder)
        // ------------------------------------------------

        data_out[0] = corrected[3];
        data_out[1] = corrected[5];
        data_out[2] = corrected[6];
        data_out[3] = corrected[7];
        data_out[4] = corrected[9];
        data_out[5] = corrected[10];
        data_out[6] = corrected[11];
        data_out[7] = corrected[12];

    end

endmodule
