# UART-16550

RTL design and FPGA implementation of UART 16550 core with Hamming ECC.

# UART 16550 Verilog Core with Hamming ECC

This repository provides a synthesizable Verilog RTL implementation of the **UART 16550** serial interface enhanced with **Hamming Error Correcting Code (ECC)**. The design includes the essential UART 16550 register interface, FIFO buffers, a configurable baud rate generator with 16× oversampling, independent transmitter and receiver modules, and integrated Hamming encoder and decoder blocks.

The enhanced UART internally uses **Hamming (12,8) ECC**, allowing 8-bit data to be encoded into a 12-bit codeword before transmission and decoded back into corrected 8-bit data at the receiver. The 12-bit encoded data is transmitted and received as a single burst through the enhanced UART datapath.

The project is verified through a dedicated RTL simulation testbench and also includes an FPGA tester module for testing the UART core on actual FPGA hardware using counter-generated test data.

---

## 📌 Overview

The **UART 16550** is a widely used asynchronous serial communication controller, historically common in PCs and embedded systems. This project implements the essential functionality of the UART 16550 and extends it with an integrated Hamming ECC datapath.

The core provides:

* Essential UART 16550 register interface.
* Transmitter (TX) and receiver (RX) with FSM-based design.
* FIFO buffering for transmit and receive data paths.
* Configurable baud rate generation.
* 16× receiver oversampling.
* Integrated **Hamming (12,8) encoder** in the transmit path.
* Integrated **Hamming (12,8) decoder** in the receive path.
* 8-bit data encoded into a 12-bit Hamming codeword.
* 12-bit encoded data transmitted and received as a single burst.
* Error detection and single-bit error correction through Hamming ECC.
* Basic interrupt mechanism currently implemented for demonstration and can be extended.
* Modular, synthesizable Verilog RTL suitable for FPGA prototyping and further ASIC implementation.
* Dedicated simulation testbench for verifying the `uart_16550.v` module.
* Dedicated FPGA tester for hardware-level UART verification using counter-generated data.


## ⚙️ Supported Registers

| Register | Description                              |
| -------- | ---------------------------------------- |
| RBR      | Receiver Buffer Register (read)          |
| THR      | Transmitter Holding Register (write)     |
| IER      | Interrupt Enable Register                |
| IIR      | Interrupt Identification Register        |
| FCR      | FIFO Control Register (optional)         |
| LCR      | Line Control Register                    |
| LSR      | Line Status Register                     |
| SCR      | Scratch Register                         |
| DLL/DLM  | Divisor Latch Low/High Bytes             |
| MCR/MSR  | Modem Control/Status Register (not used) |

## 📁 Project Structure

```text
UART-16550/
│
├── Design Sources
│   │
│   ├── fpga_uart_tester
│   │   └── fpga_tester.v
│   │
│   └── my_uart
│       └── uart_16550.v
│           │
│           ├── registers.v
│           ├── baud_rate_generator.v
│           ├── fifo.v
│           ├── tx.v
│           │   └── hamming_encoder.v
│           └── rx.v
│               └── hamming_decoder.v
│
├── Constraints
│   └── constr.xdc
│
└── Simulation Sources
    │
    ├── uart_16550_tb
    │   └── testbench.v
    │
    └── fpga_uart_tester
        └── fpga_tester.v
```

---

## 🔬 Verification

The project uses two complementary verification approaches.

### RTL Simulation

The simulation testbench verifies the logical behavior of the complete UART core.

```text
testbench.v
     │
     ▼
uart_16550.v
     │
     ├── UART functionality
     └── Hamming ECC functionality
```

### FPGA Hardware Testing

The FPGA tester verifies the implementation after synthesis and FPGA implementation.

```text
fpga_tester.v
       │
       ▼
uart_16550.v
       │
       ▼
   FPGA Hardware
```

The FPGA test uses counter-generated data to provide repeatable test patterns.

---

## 🚀 Applications

The ECC-enhanced UART architecture can be useful in systems where serial communication reliability is important, including:

* FPGA-to-FPGA communication
* Embedded systems
* Industrial communication
* Noisy communication environments
* Reliable board-to-board serial links
* Systems where single-bit error correction is desirable
* Hardware communication research and prototyping

The project also provides a useful platform for studying the integration of **error-correcting codes with conventional digital communication interfaces**.

---

## 🏗️ FPGA and ASIC Relevance

The RTL is designed using modular synthesizable Verilog, making the project suitable for FPGA implementation and further ASIC-oriented development.

---

## 🛠️ Tools Used

* **Verilog HDL**
* **Xilinx Vivado**
* **AMD Xilinx Spartan-7 XC7S50 FPGA**

---

## 🤝 Contributions

Contributions, suggestions, and improvements are welcome.

Feel free to fork the repository, open an issue, or submit a pull request.
