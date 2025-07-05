# UART-16550
Verilog RTL design of UART 16550 core with testbench and FPGA support
# UART 16550 Verilog Core

This repository provides a synthesizable Verilog RTL implementation of the industry-standard **UART 16550** serial interface. The design includes a complete register map, FIFO buffers, a configurable baud rate generator with 16× oversampling, and independent transmitter and receiver modules. The implementation has been fully verified through simulation and is ready for FPGA prototyping or ASIC integration.

---

## 📌 Overview

The **UART 16550** is a widely used asynchronous serial communication controller, historically common in PCs and embedded systems. This core replicates its essential functionality:

- Full register-compatible interface.
- Transmitter (TX) and receiver (RX) with FSM-based design.
- FIFO buffering for transmit and receive data paths.
- Baud rate generation with 16× oversampling.
- Clear, modular Verilog code, linted and synthesizable.
- Basic interrupt mechanism **currently hardcoded** for demonstration (can be extended).
- Modem control signals are **not implemented intentionally**, as they are obsolete for modern designs.

---

## ⚙️ Supported Registers

| Register | Description                                |
|----------|--------------------------------------------|
| RBR      | Receiver Buffer Register (read)            |
| THR      | Transmitter Holding Register (write)       |
| IER      | Interrupt Enable Register                  |
| IIR      | Interrupt Identification Register          |
| FCR      | FIFO Control Register (optional)           |
| LCR      | Line Control Register                      |
| LSR      | Line Status Register                       |
| SCR      | Scratch Register                           |
| DLL/DLM  | Divisor Latch Low/High Bytes               |
| MCR/MSR  | Modem Control/Status Register (not used)   |

---
Contributions and suggestions are welcome — please feel free to fork, open an issue, or submit a pull request.
