`timescale 1ns/1ps

module tx (
    input        clk,
    input        rst,
    input        baud_tick,
    input        write_thr,
    input  [7:0] thr_data,      
    input  [7:0] lcr,
    output       stx,
    output reg   thr_empty,
    output reg   tx_done
);

    // FSM States - New state added: WAIT_BAUD
    localparam IDLE      = 3'd0,
               WAIT_BAUD = 3'd5,  
               START     = 3'd1,
               DATA      = 3'd2,
               PARITY    = 3'd3,
               STOP      = 3'd4;

    reg [2:0]  state, next_state;
    reg [3:0]  tick_count;
    reg [11:0] shift_reg;        
    reg [7:0]  tx_data_latched;  
    reg        parity_bit;
    reg        stx_reg;
    reg [3:0]  bit_count;        

    wire [12:1] encoded_data;

    hamming_encoder ecc_enc (
        .data_in(tx_data_latched),
        .code(encoded_data)
    );

    wire [3:0] word_len    = 4'd12; 
    wire       parity_en   = lcr[3];
    wire       even_parity = lcr[4];

    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    // FSM Next-State Logic (SYNC FIXED)
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:      if (write_thr) next_state = WAIT_BAUD; // wait for sync
            WAIT_BAUD: if (baud_tick) next_state = START;     // start after sync arrive
            START:     if (baud_tick) next_state = DATA;
            DATA:      if (baud_tick && (bit_count == word_len - 1))
                           next_state = parity_en ? PARITY : STOP;
            PARITY:    if (baud_tick) next_state = STOP;
            STOP:      if (baud_tick) next_state = IDLE; 
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_count      <= 0;
            bit_count       <= 0;
            tx_done         <= 0;
            shift_reg       <= 0;
            tx_data_latched <= 8'h00;
        end else begin
            tx_done <= 0;

            if (write_thr) begin
                tx_data_latched <= thr_data;
            end

            if (baud_tick) begin
                tick_count <= 0;
                case (state)
                    START: begin
                        shift_reg <= encoded_data[12:1]; 
                        bit_count <= 0;
                        if (parity_en)
                            parity_bit <= even_parity ? ~(^encoded_data) : ^encoded_data;
                    end
                    DATA: begin
                        if (bit_count < word_len - 1) begin
                            shift_reg <= shift_reg >> 1;
                            bit_count <= bit_count + 1;
                        end
                    end
                    STOP: begin
                        tx_done <= 1;
                    end
                endcase
            end else if (state != IDLE) begin
                tick_count <= tick_count + 1;
            end
        end
    end

    // Serial output logic
    always @(*) begin
        case (state)
            IDLE:      stx_reg = 1'b1;
            WAIT_BAUD: stx_reg = 1'b1; // keep line high in wait state
            START:     stx_reg = 1'b0;
            DATA:      stx_reg = shift_reg[0];
            PARITY:    stx_reg = parity_bit;
            STOP:      stx_reg = 1'b1;
            default:   stx_reg = 1'b1;
        endcase
    end

    assign stx = stx_reg;

    always @(*) begin
        thr_empty = (state == IDLE);
    end

endmodule
