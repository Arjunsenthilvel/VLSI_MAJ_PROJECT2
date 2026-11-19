`timescale 1ns/1ps
// UART Receiver: 8N1, LSB first, mid-bit sampling
module uart_rx #(parameter CLKS_PER_BIT = 5208)
(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg  [7:0] rx_data,
    output reg        rx_done,                     // 1-clock pulse when a byte is valid
    output reg        frame_err                    // stop bit was not 1
);
    localparam IDLE=2'd0, START=2'd1, DATA=2'd2, STOP=2'd3;

    reg        rx_m, rx_s;                         // 2-FF synchronizer
    reg [1:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_shift_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_m <= 1'b1; rx_s <= 1'b1;
            state <= IDLE; clk_count <= 0; bit_index <= 0;
            rx_shift_reg <= 0; rx_data <= 0; rx_done <= 0; frame_err <= 0;
        end else begin
            rx_m <= rx; rx_s <= rx_m;
            rx_done <= 1'b0;
            case (state)
            IDLE: begin
                clk_count <= 0; bit_index <= 0;
                if (!rx_s) state <= START;
            end
            START: begin                            // wait to middle of start bit
                if (clk_count == (CLKS_PER_BIT-1)/2) begin
                    clk_count <= 0;
                    if (!rx_s) state <= DATA;       // still low -> valid start
                    else       state <= IDLE;       // glitch
                end else clk_count <= clk_count + 1;
            end
            DATA: begin                             // sample every full bit time
                if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    rx_shift_reg[bit_index] <= rx_s;
                    if (bit_index == 7) state <= STOP;
                    else bit_index <= bit_index + 1;
                end
            end
            STOP: begin
                if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    rx_data   <= rx_shift_reg;
                    rx_done   <= 1'b1;
                    frame_err <= ~rx_s;
                    state     <= IDLE;
                end
            end
            endcase
        end
    end
endmodule
