# UART Design and Simulation using Verilog

Major Project 2 – Batch GL605A, Glowlogics (VLSI Design)

A synthesizable **UART transmitter and receiver (8N1)** written in Verilog, verified in loopback with a self-checking testbench using only open-source tools (Icarus Verilog, GTKWave, Yosys).

- **Baud rate:** 9600 (50 MHz clock, `CLKS_PER_BIT = 5208`, 0.006 % error)
- **Frame:** 1 start bit, 8 data bits (LSB first), no parity, 1 stop bit
- **Receiver:** 2-FF input synchronizer, mid-bit sampling, glitch rejection, framing-error flag

## Repository structure

```
├── src/
│   ├── uart_tx.v        # Transmitter
│   └── uart_rx.v        # Receiver
├── tb/
│   └── uart_tb.v        # Self-checking loopback testbench (dumps dump.vcd)
├── docs/
│   ├── UART_Project_Report.pdf
│   ├── simulation_output.txt / .png
│   ├── wave_frame.png   # one frame (0xA5)
│   └── wave_all.png     # all 8 test bytes
├── Makefile
├── LICENSE
└── README.md
```

## Module interfaces

| Module | Port | Dir | Description |
|---|---|---|---|
| `uart_tx` | `clk`, `rst` | in | Clock, async active-high reset |
| | `tx_start` | in | Pulse to send `tx_data` (ignored while busy) |
| | `tx_data[7:0]` | in | Byte to transmit |
| | `tx` | out | Serial output (idle = 1) |
| | `tx_busy` | out | High while a frame is being sent |
| `uart_rx` | `rx` | in | Serial input |
| | `rx_data[7:0]` | out | Received byte |
| | `rx_done` | out | 1-clock pulse, `rx_data` valid |
| | `frame_err` | out | Stop bit was not 1 |

Both modules take a `CLKS_PER_BIT` parameter = `f_clk / baud` (e.g. 434 for 115200 baud at 50 MHz).

## Quick start

Requires `iverilog`, `gtkwave` (optional) and `yosys` (optional):

```bash
sudo apt install iverilog gtkwave yosys
make sim      # compile + run the testbench
make wave     # open dump.vcd in GTKWave
make synth    # Yosys iCE40 resource estimate
```

## Simulation result

```
[989 us] PASS  sent=0xa5  received=0xa5
[2031 us] PASS  sent=0x5a  received=0x5a
[3073 us] PASS  sent=0x00  received=0x00
[4115 us] PASS  sent=0xff  received=0xff
[5157 us] PASS  sent=0x48  received=0x48
[6199 us] PASS  sent=0x69  received=0x69
[7241 us] PASS  sent=0x01  received=0x01
[8283 us] PASS  sent=0x80  received=0x80
RESULT: ALL 8 TESTS PASSED
```

![One UART frame](docs/wave_frame.png)
![All test bytes](docs/wave_all.png)

## Synthesis (Yosys, iCE40)

| Resource | uart_tx | uart_rx |
|---|---|---|
| LUT4 | 69 | 93 |
| Carry | 28 | 29 |
| Flip-flops | 31 | 43 |
| Total cells | 128 | 165 |

## Notes

Fixes made relative to the original course template: corrected baud divider (868 → 5208), receiver no longer samples the start bit as data bit 0, full-length stop bit, input synchronizer, `$dumpfile` added, and testbench made self-checking. See `docs/UART_Project_Report.pdf` for details.

## Future work

Parity / 2 stop bits, TX/RX FIFOs, 16x oversampling, and FPGA implementation (iCEstick / ULX3S) with nextpnr + openFPGALoader.

## License

MIT
