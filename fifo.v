`timescale 1ns / 1ps

module fifo (
    input clk,
    input rst,
    input wr_en,
    input rd_en,
    input [7:0] din,
    output wire [7:0] dout, // <--- CHANGE TO 'wire'
    output reg [4:0] count,
    output full,
    output empty
);

    reg [7:0] mem [0:15]; // 16-byte memory
    reg [3:0] rd_ptr, wr_ptr;
    integer i;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            mem[i] = 8'h00; // Initialize all memory locations to 0 at time 0
        end
        rd_ptr = 0;
        wr_ptr = 0;
        count = 0;
        // dout is wire, no need to set here
    end
    assign full  = (count == 5'd16);  
    assign empty = (count == 0);

    // Make dout combinational from the memory, based on rd_ptr
    assign dout = mem[rd_ptr]; // <--- ADD THIS LINE HERE (combinational assignment)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            rd_ptr <= 0;
            wr_ptr <= 0;
            
        end else begin
            // Write Logic
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= (wr_ptr == 15) ? 0 : wr_ptr + 1;
            end

            // Read Pointer Update Logic (dout is combinational, so only pointer updates here)
            if (rd_en && !empty) begin
                rd_ptr <= (rd_ptr == 15) ? 0 : rd_ptr + 1;
            end

            // Update count atomically
            case ({wr_en && !full, rd_en && !empty})
                2'b01: count <= count - 1; // Only read
                2'b10: count <= count + 1; // Only write
                2'b11: count <= count;     // Both read and write (count remains same)
                default: count <= count;   // No change (neither read nor write)
            endcase
            
        end
    end
endmodule