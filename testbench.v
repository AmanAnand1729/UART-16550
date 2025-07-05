`timescale 1ns / 1ps

module uart_16550_tb;

    parameter CLK_PERIOD = 10;
    parameter BAUD_PERIOD = 104167; // For 9600 baud at 100 MHz

    reg clk;
    reg rst;

    // CPU Interface
    reg cs;
    reg wr;
    reg [2:0] addr;
    reg [7:0] wdata;
    wire [7:0] rdata;
    wire irq;

    // UART Interface
    reg rx;
    wire tx;
    wire out1;
    wire out2;

    integer error_count = 0;

    // DUT
    uart_16550 uut (
        .clk(clk),
        .rst(rst),
        .cs(cs),
        .wr(wr),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata),
        .irq(irq),
        .rx(rx),
        .tx(tx),
        .out1(out1),
        .out2(out2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        rst = 1;
        cs = 0;
        wr = 0;
        addr = 0;
        wdata = 0;
        rx = 1;

        #(10 * CLK_PERIOD);
        rst = 0;
        #(10 * CLK_PERIOD);

        $display("\n=== Starting UART 16550 Testbench ===");
        $display("Time\tTest\t\t\tResult");
        $display("----------------------------------------");

        test_register_access();
        test_baud_config();
        test_transmission();
        test_reception();

        $display("\n=== Test Summary ===");
        $display("Total tests run: 4");
        $display("Errors detected: %0d", error_count);
        if (error_count == 0)
            $display("SUCCESS: All tests passed!");
        else
            $display("FAIL: %0d tests failed", error_count);

        $finish;
    end

    // --- Tasks ---

    task write_register;
        input [2:0] reg_addr;
        input [7:0] data;
        begin
            @(posedge clk);
            cs = 1;
            wr = 1;
            addr = reg_addr;
            wdata = data;
            @(posedge clk);
            cs = 0;
            wr = 0;
            @(posedge clk);
            $display("Write: addr=%0d, data=0x%h", reg_addr, data);
        end
    endtask

    task read_register;
        input [2:0] reg_addr;
        output [7:0] data;
        begin
            @(posedge clk);
            cs = 1;
            wr = 0; // READ when WR=0
            addr = reg_addr;
            @(posedge clk);
            data = rdata;
            cs = 0;
            @(posedge clk);
        end
    endtask

    task check_result;
        input [80:0] test_name;
        input [7:0] actual;
        input [7:0] expected;
        begin
            if (actual === expected)
                $display("PASS: %s (0x%h)", test_name, actual);
            else begin
                $error("FAIL: %s (Got: 0x%h, Expected: 0x%h)", test_name, actual, expected);
                error_count = error_count + 1;
            end
        end
    endtask

    task test_register_access;
        reg [7:0] read_val;
        begin
            $display("Test 1: Register Access");
            write_register(3'b111, 8'hAA);
            read_register(3'b111, read_val);
            check_result("SCR Write/Read", read_val, 8'hAA);
            write_register(3'b011, 8'b00000011);
            read_register(3'b011, read_val);
            check_result("LCR Configuration", read_val, 8'b00000011);
        end
    endtask

    task test_baud_config;
        reg [7:0] read_val;
        begin
            $display("Test 2: Baud Rate Configuration");
            write_register(3'b011, 8'b10000011);
            write_register(3'b000, 8'h8B);
            write_register(3'b001, 8'h02);
            read_register(3'b000, read_val);
            check_result("DLL Readback", read_val, 8'h8B);
            read_register(3'b001, read_val);
            check_result("DLM Readback", read_val, 8'h02);
            write_register(3'b011, 8'b00000011);
        end
    endtask

    task test_transmission;
        reg [7:0] read_val;
        reg tx_complete;
        begin
            $display("Test 3: Transmission Test");
            write_register(3'b000, 8'h55);
            wait(tx == 0);
            $display("TX start bit detected at %t", $time);

            tx_complete = 0;
            while (!tx_complete) begin
                @(posedge clk);
                read_register(3'b101, read_val);
                if (read_val[6] === 1'b1)
                    tx_complete = 1;
            end

            $display("TX: %t Transmission completed. LSR: 0x%h", $time, read_val);
            read_register(3'b101, read_val);
            if (read_val[6] === 1'b1)
                $display("PASS: Transmission completed");
            else begin
                $error("FAIL: Transmission not completed. LSR value: 0x%h", read_val);
                error_count = error_count + 1;
            end
        end
    endtask

    task test_reception;
        reg [7:0] read_val;
        integer i;
        reg [7:0] data_to_send;
        begin
            data_to_send = 8'hA5;
            $display("Test 4: Reception Test");
            rx = 1'b1;
            #(BAUD_PERIOD * 2);

            rx = 1'b0;
            #(BAUD_PERIOD);
            for (i = 0; i < 8; i = i + 1) begin
                rx = data_to_send[i];
                #(BAUD_PERIOD);
            end
            rx = 1'b1;
            #(BAUD_PERIOD * 3);

            read_register(3'b101, read_val);
            if (read_val[0] !== 1'b1) begin
                $error("FAIL: No data received. LSR = 0x%h", read_val);
                error_count = error_count + 1;
            end else begin
                $display("PASS: Data Ready. LSR = 0x%h", read_val);
            end

            read_register(3'b000, read_val);
            check_result("Received Data", read_val, data_to_send);
        end
    endtask

    always @(negedge tx) begin
        $display("TX start bit detected at %t", $time);
    end

endmodule
