`timescale 1ns/1ps

module hamming_encoder (

    input  [7:0]  data_in,
    output reg [12:1] code

);

    integer i, j;

    reg [3:0] parity;

    always @(*) begin

        code = 0;
        parity = 0;

        // Data placement
        code[3]  = data_in[0];
        code[5]  = data_in[1];
        code[6]  = data_in[2];
        code[7]  = data_in[3];
        code[9]  = data_in[4];
        code[10] = data_in[5];
        code[11] = data_in[6];
        code[12] = data_in[7];

        // Parity calculation
        for(i = 1; i <= 12; i = i + 1) begin

            // Skip parity positions
            if((i & (i-1)) != 0) begin //if not a power of 2 (power of 2 has parity so skip it)

                for(j = 0; j < 4; j = j + 1) begin

                    if((i >> j) & 1) //i[j] is 1. we can also write i[j] but some synthesis tools dislike bit-select on integer
                        parity[j] =
                            parity[j] ^ code[i];

                end
            end
        end

        // Insert parity bits
        code[1] = parity[0];
        code[2] = parity[1];
        code[4] = parity[2];
        code[8] = parity[3];

    end

endmodule
