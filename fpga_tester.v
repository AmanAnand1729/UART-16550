`timescale 1ns / 1ps

module fpga_uart_tester (
    input        clk,             // 100 MHz System Clock
    input        rst_btn,         // Reset button (Active High)
    input        err_inject_btn,  // Push button to inject a 1-bit error
    output reg [7:0] data_leds,   // 8 LEDs to display the counter
    output reg   ecc_detect_led,  // 1 LED to show error detected
    output reg   ecc_correct_led  // 1 LED to show error corrected
);

    // --- UART Signals ---
    reg  cs, wr;
    reg  [2:0] addr;
    reg  [7:0] wdata;
    wire [7:0] rdata;
    wire irq, tx_wire;
    
    // --- The Physical Serial Line ---
    reg flip_bit; 
    wire rx_wire = tx_wire ^ flip_bit; // async wire , no delays

    // --- Instantiate the UART ---
    uart_16550 my_uart (
        .clk(clk),
        .rst(rst_btn),
        .cs(cs),
        .wr(wr),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .irq(irq),
      .rx(rx_wire), // Wire connected
        .tx(tx_wire),
        .out1(), 
        .out2()  
    );

    // =========================================================
    // 1. SERIAL GLITCH FSM (1ms Relaxed Debounce & Switch Mode)
    // =========================================================
    
    // Upgraded Debouncer for Slide Switch (1ms wait - ignores noise but catches the switch)
    reg [19:0] debounce_timer; 
    reg btn_stable;
    
    always @(posedge clk) begin
        if (rst_btn) begin
            debounce_timer <= 0;
            btn_stable <= 0;
        end else begin
            if (err_inject_btn == btn_stable) begin
                debounce_timer <= 0;
            end else begin
                debounce_timer <= debounce_timer + 1;
                // Wait approx 1ms (100,000 clocks @ 100MHz)
                if (debounce_timer == 20'd100_000) begin
                    btn_stable <= err_inject_btn;
                    debounce_timer <= 0;
                end
            end
        end
    end

    localparam G_IDLE       = 2'd0,
               G_WAIT_START = 2'd1,
               G_COUNT_BITS = 2'd2,
               G_DONE       = 2'd3;
               
    reg [1:0]  g_state;
    reg [16:0] g_baud_timer;
    reg [3:0]  g_bit_count;

    always @(posedge clk or posedge rst_btn) begin
        if (rst_btn) begin
            g_state      <= G_IDLE;
            flip_bit     <= 1'b0;
            g_baud_timer <= 0;
            g_bit_count  <= 0;
        end else begin
            case (g_state)
                G_IDLE: begin
                    flip_bit <= 1'b0;
                    // Switch ON hai aur UART idle hai, toh hi arm karo
                    if (btn_stable == 1'b1 && tx_wire == 1'b1) 
                        g_state <= G_WAIT_START; 
                end
                
                G_WAIT_START: begin
                    if (tx_wire == 1'b0) begin 
                        g_state      <= G_COUNT_BITS;
                        g_baud_timer <= 0;
                        g_bit_count  <= 0;
                    end
                end
                
                G_COUNT_BITS: begin
                    if (g_baud_timer == 17'd10416) begin // 9600 baud @ 100MHz
                        g_baud_timer <= 0;
                        g_bit_count  <= g_bit_count + 1;
                        if (g_bit_count == 4'd12) g_state <= G_DONE; 
                    end else begin
                        g_baud_timer <= g_baud_timer + 1;
                    end

                    // Target Data Bit 5
                    if (g_bit_count == 4'd6) flip_bit <= 1'b1; 
                    else flip_bit <= 1'b0;
                end
                
                G_DONE: begin
                    flip_bit <= 1'b0;
                    if (tx_wire == 1'b1) g_state <= G_IDLE; 
                end
            endcase
        end
    end

    // =========================================================
    // 2. CPU MASTER FSM (Parity ON & Bus Idle Cycles)
    // =========================================================
    
    reg [26:0] one_sec_timer; 
    reg [4:0]  m_state;
    reg [7:0]  counter_data;

    always @(posedge clk or posedge rst_btn) begin
        if (rst_btn) begin
            m_state         <= 5'd0;
            counter_data    <= 8'd0;
            data_leds       <= 8'd0;
            ecc_detect_led  <= 1'b0;
            ecc_correct_led <= 1'b0;
            one_sec_timer   <= 27'd0;
            cs <= 1'b0; wr <= 1'b0; addr <= 3'b000; wdata <= 8'd0;
        end else begin
            case (m_state)
                // --- Safe Initialization ---
                0:  begin cs<=1; wr<=1; addr<=3'b011; wdata<=8'h83; m_state<=1;  end 
                1:  begin cs<=0; wr<=0; m_state<=2; end                              
                2:  begin cs<=1; wr<=1; addr<=3'b000; wdata<=8'h8B; m_state<=3;  end 
                3:  begin cs<=0; wr<=0; m_state<=4; end                              
                4:  begin cs<=1; wr<=1; addr<=3'b001; wdata<=8'h02; m_state<=5;  end 
                5:  begin cs<=0; wr<=0; m_state<=6; end                              
                
                
                6:  begin cs<=1; wr<=1; addr<=3'b011; wdata<=8'h03; m_state<=7;  end 
                7:  begin cs<=0; wr<=0; m_state<=8; end            

                // --- FLUSH FIFOs ---
                8:  begin cs<=1; wr<=1; addr<=3'b010; wdata<=8'h07; m_state<=9;  end 
                9:  begin cs<=0; wr<=0; m_state<=10; one_sec_timer<=0; end

                // --- 1. HARD 1 SECOND DELAY ---
                10: begin
                    cs <= 0; wr <= 0; 
                    if (one_sec_timer >= 27'd100_000_000) begin
                        one_sec_timer <= 27'd0;
                        m_state <= 11; 
                    end else begin
                        one_sec_timer <= one_sec_timer + 1;
                    end
                end

                // --- 2. TRANSMIT 1 BYTE ---
                11: begin 
                    cs <= 1; wr <= 1; addr <= 3'b000; 
                    wdata <= counter_data; 
                    data_leds <= counter_data; 
                    m_state <= 12; 
                end 
                12: begin cs <= 0; wr <= 0; m_state <= 13; end

                // --- 3. RELAX FOR 2ms ---
                13: begin
                    if (one_sec_timer >= 27'd200_000) begin 
                        one_sec_timer <= 0;
                        m_state <= 14;
                    end else begin
                        one_sec_timer <= one_sec_timer + 1;
                    end
                end

                // --- 4. READ LSR (Check Flags) ---
                14: begin cs <= 1; wr <= 0; addr <= 3'b101; m_state <= 15; end 
                15: begin m_state <= 16; end 
                16: begin
                    ecc_detect_led  <= rdata[7]; 
                    ecc_correct_led <= rdata[2]; 
                    cs <= 0; m_state <= 17; 
                end
                
                // --- HARD IDLE CYCLE ---
                17: begin m_state <= 18; end 

                // --- 5. READ RBR (Pop the FIFO) ---
                18: begin cs <= 1; wr <= 0; addr <= 3'b000; m_state <= 19; end 
                19: begin m_state <= 20; end 
                20: begin
                    counter_data <= counter_data + 1; 
                    cs <= 0; 
                    m_state <= 10; // Loop back
                end
                
                default: m_state <= 0;
            endcase
        end
    end
endmodule
