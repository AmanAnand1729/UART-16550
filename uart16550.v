
`timescale 1ns / 1ps

module uart_16550 (
    input         clk,        // System clock
    input         rst,        // System reset (active high)
    
    // CPU Interface
    input         cs,         // Chip select
    input         wr,         // Write enable
    //input         rd,         // Read enable
    input  [2:0]  addr,       // Register address
    input  [7:0]  wdata,      // Data input from CPU
    output [7:0]  rdata,      // Data output to CPU
    output        irq,        // Interrupt output
    
    // UART Interface
    input         rx,         // Serial receive
    output        tx,         // Serial transmit
    output        out1,       // Output 1 ( modem control)
    output        out2        // Output 2 ( IRQ enable)
);

    // Internal signals
    wire [7:0] rbr, iir, lsr, thr;
    wire [7:0] dll, dlm, ier, lcr, scr;
    wire write_thr, read_rbr, load_divisor;
    wire fifo_rst_tx, fifo_rst_rx;
    wire tick16;
    // Baud generator signals
    wire baud_tick;
    
    // Transmitter signals
    wire tx_done, thr_empty;
    
    // Receiver signals
    wire rbr_full, frame_err, parity_err;
    
    // FIFO signals
    wire [7:0] tx_fifo_out, rx_fifo_out;
    wire [3:0] tx_fifo_count, rx_fifo_count;
    wire tx_fifo_full, tx_fifo_empty;
    wire rx_fifo_full, rx_fifo_empty;
    
    // FIFO control signals
    wire tx_fifo_wr = write_thr && !lcr[7]; // Don't write when DLAB=1
    wire tx_fifo_rd = (thr_empty && !tx_fifo_empty); // Read when transmitter is idle and FIFO has data
    wire rx_fifo_wr = rbr_full;
    wire rx_fifo_rd = read_rbr;
    
     wire [7:0] rx_rbr_output; // This will connect to receiver.rbr
    wire rx_rbr_full_output;  // This will connect to receiver.rbr_full

    // Registered version of rx_rbr_full_output for FIFO wr_en
    reg rx_fifo_wr_delayed;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_fifo_wr_delayed <= 1'b0;
        end else begin
            rx_fifo_wr_delayed <= rx_rbr_full_output; // Delay rx_rbr_full by one clock cycle
        end
    end
    // Line Status Register (LSR) bits
    assign lsr = {
        1'b0,                      // [7] - Unused
        (thr_empty && tx_fifo_empty), // [6] - TEMT (Transmitter empty and FIFO empty)
        thr_empty,                 // [5] - THRE (Transmitter holding register empty)
        frame_err,                 // [4] - Framing error
        parity_err,                // [3] - Parity error
        1'b0,                      // [2] - Break interrupt (not implemented)
        (rx_fifo_full && rbr_full), // [1] - Overrun error (if FIFO full and new data arrives)
        !rx_fifo_empty             // [0] - Data ready
    };
    
    // Interrupt Identification Register (IIR) bits
    // Simplified: only data available interrupt for now
    assign iir = 8'b0000_0100; // Interrupt when data available (if enabled in IER)
    
    // Modem control outputs (not fully implemented)
    assign out1 = 1'b0;
    assign out2 = 1'b0;
    
    // Instantiate Register File
    registers reg_file (
    
        .clk(clk),
        .rst(rst),
        .cs(cs),
        .wr(wr),
        //.rd(rd),
        .addr(addr),
        .wdata(wdata),
        .rbr(rx_fifo_out), // Connected to FIFO output
        .iir(iir),
        .lsr(lsr),
        .thr(tx_fifo_out), // Connected to FIFO output
        .rdata(rdata),
        .dll(dll),
        .dlm(dlm),
        .ier(ier),
        .lcr(lcr),
        .scr(scr),
        .write_thr(write_thr),
        .read_rbr(read_rbr),
        .load_divisor(load_divisor),
        .fifo_rst_tx(fifo_rst_tx),
        .fifo_rst_rx(fifo_rst_rx)
    );
    
    // Instantiate Baud Rate Generator
    baud_rate_generator baud_gen (
        .clk(clk),
        .rst(rst),
        .load_divisor(load_divisor),
        .dll(dll),
        .dlm(dlm),
        .baud_tick(baud_tick),
        .tick16(tick16)
    );
    
    // Instantiate Transmitter FIFO
    fifo tx_fifo (
        .clk(clk),
        .rst(rst | fifo_rst_tx),
        .wr_en(tx_fifo_wr),
        .rd_en(tx_fifo_rd),
        .din(wdata), // Data from CPU write
        .dout(tx_fifo_out), // To transmitter
        .count(tx_fifo_count),
        .full(tx_fifo_full),
        .empty(tx_fifo_empty)
    );

    // Instantiate Receiver FIFO
    fifo rx_fifo (
        .clk(clk),
        .rst(rst | fifo_rst_rx),
        .wr_en(rx_fifo_wr_delayed),
        .rd_en(read_rbr),
        .din(rx_rbr_output), // From receiver
        .dout(rx_fifo_out), // To register file
        .count(rx_fifo_count),
        .full(rx_fifo_full),
        .empty(rx_fifo_empty)
    );
    // In uart_16550.v
// Add inside an initial block or an always @(posedge clk) block for continuous monitoring
    // Instantiate Transmitter
    tx transmitter (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .write_thr(tx_fifo_rd), // When FIFO read, we write to transmitter
        .thr_data(tx_fifo_out),
        .lcr(lcr),
        .stx(tx),
        .thr_empty(thr_empty),
        .tx_done(tx_done)
    );
    
    // Instantiate Receiver
    rx receiver (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .tick16(tick16),
        .srx(rx), // Connect to top's rx input
        .lcr(lcr),
        .rbr(rx_rbr_output),
        .rbr_full(rx_rbr_full_output),
        .frame_err(frame_err),
        .parity_err(parity_err)
    );
    
    // Interrupt generation: when RX FIFO not empty and interrupt enabled for data available
    assign irq = !rx_fifo_empty && ier[0];

endmodule
