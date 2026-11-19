`timescale 1ns/1ps
// UART Transmitter: 8N1, LSB first
module uart_tx #(parameter CLKS_PER_BIT = 5208)   // 50 MHz / 9600 baud
(
    input  wire       clk,
    input  wire       rst,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx,
    output reg        tx_busy
);
    reg [15:0] clk_count;
    reg [3:0]  bit_index;
    reg [9:0]  tx_shift_reg;                       // {Stop, Data[7:0], Start}

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx <= 1'b1; tx_busy <= 1'b0;
            clk_count <= 0; bit_index <= 0;
            tx_shift_reg <= 10'h3FF;
        end else if (!tx_busy) begin
            if (tx_start) begin
                tx_shift_reg <= {1'b1, tx_data, 1'b0};
                tx        <= 1'b0;                 // start bit begins immediately
                tx_busy   <= 1'b1;
                clk_count <= 0;
                bit_index <= 0;
            end
        end else begin
            if (clk_count < CLKS_PER_BIT-1) begin
                clk_count <= clk_count + 1;
            end else begin
                clk_count <= 0;
                if (bit_index == 9) begin          // stop bit has lasted a full bit time
                    tx_busy <= 1'b0;
                    tx      <= 1'b1;
                end else begin
                    bit_index <= bit_index + 1;
                    tx        <= tx_shift_reg[bit_index + 1];
                end
            end
        end
    end
endmodule
