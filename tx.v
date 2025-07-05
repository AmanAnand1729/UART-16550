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

    // FSM States
    localparam IDLE   = 3'd0,
               START  = 3'd1,
               DATA   = 3'd2,
               PARITY = 3'd3,
               STOP   = 3'd4;

    reg [2:0]  state, next_state;
    reg [3:0]  tick_count;
    reg [7:0]  shift_reg;
    reg [7:0]  tx_data_latched;  // <-- NEW: holds THR data
    reg        parity_bit;
    reg        stx_reg;
    reg [2:0]  bit_count;

    // LCR decoding
    wire [1:0] word_len_sel = lcr[1:0];
    wire [3:0] word_len = (word_len_sel == 2'b00) ? 4'd5 :
                          (word_len_sel == 2'b01) ? 4'd6 :
                          (word_len_sel == 2'b10) ? 4'd7 : 4'd8;
    wire       parity_en   = lcr[3];
    wire       even_parity = lcr[4];
    wire       stop_bit2   = lcr[2];

    // FSM State Register
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM Next-State Logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   if (write_thr) next_state = START;
            START:  if (baud_tick) next_state = DATA;
            DATA:   if (baud_tick && (bit_count == word_len - 1))
                        next_state = parity_en ? PARITY : STOP;
            PARITY: if (baud_tick) next_state = STOP;
            STOP:   if (baud_tick) next_state = IDLE;
        endcase
    end

    // Main FSM behavior
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tick_count     <= 0;
            bit_count      <= 0;
            tx_done        <= 0;
            shift_reg      <= 0;
            stx_reg        <= 1'b1;
            tx_data_latched <= 8'h00;
        end else begin
            tx_done <= 0;

            // Latch data immediately on write_thr
            if (write_thr) begin
                tx_data_latched <= thr_data;
                $display("TX: Data latched immediately: 0x%h", thr_data);
            end

            if (baud_tick) begin
                tick_count <= 0;

                case (state)
                    START: begin
                        shift_reg <= tx_data_latched; // <-- Use latched data
                        bit_count <= 0;
                        if (parity_en)
                            parity_bit <= even_parity ? ~(^tx_data_latched) : ^tx_data_latched;
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
            IDLE:    stx_reg = 1'b1;
            START:   stx_reg = 1'b0;
            DATA:    stx_reg = shift_reg[0];
            PARITY:  stx_reg = parity_bit;
            STOP:    stx_reg = 1'b1;
            default: stx_reg = 1'b1;
        endcase
    end

    assign stx = stx_reg;

    // THR empty flag
    always @(*) begin
        thr_empty = (state == IDLE);
    end

    // Debug printing
    always @(posedge clk) begin
        if (write_thr)
            $display("TX: Data latched: 0x%h", thr_data);
    end

    always @(posedge clk) begin
        if (baud_tick)
            $display("TX DEBUG: %t baud_tick HIGH, state=%0d, bit_count=%0d", $time, state, bit_count);
    end

    always @(posedge clk) begin
        if (baud_tick && (state == DATA || state == PARITY || state == STOP))
            $display("TX BIT @ %t ns: tx = %b, bit_count = %0d", $time, stx, bit_count);
    end

    always @(stx) begin
        $display("TX CHANGE @ %t ns: tx = %b", $time, stx);
    end

endmodule
