`timescale 1ns/1ps
module registers (
    input clk, rst, cs, wr,rd,
    input [2:0] addr,
    input [7:0] wdata, rbr, iir, lsr, thr,
    output [7:0]  dll, dlm, ier, lcr, scr,
    output reg write_thr, read_rbr, load_divisor, fifo_rst_tx, fifo_rst_rx,
    output reg [7:0] rdata
);
    reg [7:0] fcr;
    wire dlab = lcr[7];  // DLAB bit from LCR
    
    // Register storage
    reg [7:0] scr_reg;
    reg [7:0] lcr_reg;
    reg [7:0] dll_reg;
    reg [7:0] dlm_reg;
    reg [7:0] ier_reg;
    reg [7:0] iir_reg;
    reg [7:0] lsr_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dll_reg <= 8'd0;
            dlm_reg <= 8'd0;
            ier_reg <= 8'd0;
            lcr_reg <= 8'd0;
            scr_reg <= 8'd0;
            fcr <= 8'd0;
            write_thr <= 1'b0;
            load_divisor <= 1'b0;
            fifo_rst_tx <= 1'b0;
            fifo_rst_rx <= 1'b0;
            //$display("REG: %t Reset asserted", $time);
        end else begin
            write_thr <= 1'b0;
            load_divisor <= 1'b0;
            fifo_rst_tx <= 1'b0;
            fifo_rst_rx <= 1'b0;

            if (cs && wr) begin
            
                case (addr)
                    3'd0: begin
                        if (dlab) begin
                            dll_reg <= wdata;
                            load_divisor <= 1'b1;
                        end else begin
                            write_thr <= 1'b1;
                        end
                    end
                    3'd1: begin
                        if (dlab) begin
                            dlm_reg <= wdata;
                            load_divisor <= 1'b1;
                        end else begin
                            ier_reg <= wdata;
                        end
                    end
                    3'd2: begin
                        fcr <= wdata;
                        fifo_rst_rx <= wdata[1];  
                        fifo_rst_tx <= wdata[2];
                    end
                    3'd3: lcr_reg <= wdata;
                    3'd7: scr_reg <= wdata;
                    default: ; // No action for other addresses
                endcase
            end
        end
    end
    
    // Continuous assignments for outputs
    assign dll = dll_reg;
    assign dlm = dlm_reg;
    assign ier = ier_reg;
    assign lcr = lcr_reg;
    assign scr = scr_reg;

    // Read logic
    always @(*) begin
        rdata = 8'd0;
        read_rbr = 1'b0;

        if (cs && !wr) begin
        
            case (addr)
                3'd0: begin
                    if (dlab) begin
                        rdata = dll_reg;
                        
                   end else begin
                        rdata = rbr;
                        read_rbr = 1'b1;
                        
                    end
                end
                3'd1: begin // IER or DLM
                    if (dlab) begin
                        rdata = dlm_reg;
                        
                    end else begin
                        rdata = ier_reg;
                        
                    end
                end
                3'd2: begin // IIR (Interrupt Identification Register)
                    rdata = iir;
                    
                end
                3'd3: begin // LCR (Line Control Register)
                    rdata = lcr_reg;
                    
                end
                3'd5: begin // LSR (Line Status Register)
                    rdata = lsr;
                    
                end
                3'd7: begin // SCR (Scratchpad Register)
                    rdata = scr_reg;
                    
                end
                default: begin
                    rdata = 8'h00; // Default for unmapped address reads
                   
                end
            endcase
        end
    end

endmodule