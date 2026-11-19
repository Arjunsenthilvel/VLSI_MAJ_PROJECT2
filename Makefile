SRC = src/uart_tx.v src/uart_rx.v tb/uart_tb.v

all: sim

uart_sim: $(SRC)
	iverilog -Wall -o uart_sim $(SRC)

sim: uart_sim
	vvp uart_sim

wave: sim
	gtkwave dump.vcd

synth:
	yosys -p "read_verilog src/uart_tx.v; synth_ice40 -top uart_tx; stat"
	yosys -p "read_verilog src/uart_rx.v; synth_ice40 -top uart_rx; stat"

clean:
	rm -f uart_sim dump.vcd
