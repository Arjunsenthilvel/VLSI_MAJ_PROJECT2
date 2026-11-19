`timescale 1ns/1ps
module uart_tb;
    parameter CLKS_PER_BIT = 5208;                  // 50 MHz / 9600 baud
    reg clk, rst, tx_start;
    reg [7:0] tx_data;
    wire tx, tx_busy, rx_done, frame_err;
    wire [7:0] rx_data;

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) tx_unit (.clk(clk), .rst(rst), .tx_start(tx_start),
        .tx_data(tx_data), .tx(tx), .tx_busy(tx_busy));
    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) rx_unit (.clk(clk), .rst(rst), .rx(tx),   // loopback
        .rx_data(rx_data), .rx_done(rx_done), .frame_err(frame_err));

    initial begin clk = 0; forever #10 clk = ~clk; end     // 50 MHz

    integer i, errors = 0;
    reg [7:0] test_vec [0:7];

    task send_and_check(input [7:0] d);
        begin
            @(posedge clk); tx_data = d; tx_start = 1;
            @(posedge clk); tx_start = 0;
            @(posedge rx_done);
            @(negedge clk);
            if (rx_data === d && !frame_err)
                $display("[%0d us] PASS  sent=0x%02h  received=0x%02h", $time/1000, d, rx_data);
            else begin
                $display("[%0d us] FAIL  sent=0x%02h  received=0x%02h  frame_err=%b", $time/1000, d, rx_data, frame_err);
                errors = errors + 1;
            end
            wait(!tx_busy);
            repeat (20) @(posedge clk);
        end
    endtask

    initial begin
        $dumpfile("dump.vcd"); $dumpvars(0, uart_tb);
        test_vec[0]=8'hA5; test_vec[1]=8'h5A; test_vec[2]=8'h00; test_vec[3]=8'hFF;
        test_vec[4]=8'h48; test_vec[5]=8'h69; test_vec[6]=8'h01; test_vec[7]=8'h80;
        rst = 1; tx_start = 0; tx_data = 0;
        #100; rst = 0; #100;
        for (i = 0; i < 8; i = i + 1) send_and_check(test_vec[i]);
        $display("----------------------------------------");
        if (errors == 0) $display("RESULT: ALL 8 TESTS PASSED");
        else             $display("RESULT: %0d TEST(S) FAILED", errors);
        $finish;
    end
    initial begin #20_000_000; $display("TIMEOUT"); $finish; end   // 20 ms watchdog
endmodule
