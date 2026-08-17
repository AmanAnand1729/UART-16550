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

```

## 🛡️ Hamming ECC

The project uses a **Hamming (12,8)** code to provide error-correction capability for the UART data path.

The encoder converts:

```text
8-bit data
    ↓
Hamming Encoder
    ↓
12-bit codeword
```

The resulting 12-bit Hamming codeword is transmitted as a single burst through the enhanced UART transmitter.

At the receiver:

```text
12-bit received codeword
          ↓
   Hamming Decoder
          ↓
 Corrected 8-bit data
```

The Hamming decoder generates a syndrome that is used to identify an error and correct a single-bit error when present.

The Hamming code uses four parity bits along with eight data bits:

```text
8 data bits + 4 parity bits = 12-bit codeword
```

Parity positions are located at:

```text
1, 2, 4, 8
```

while the remaining positions contain the eight data bits.

---

## 🔄 Data Flow

### Transmit Path

The transmit datapath operates as:

```text
CPU Data
   │
   ▼
Hamming Encoder
   │
   ▼
12-bit Hamming Codeword
   │
   ▼
TX FIFO / Transmitter
   │
   ▼
UART TX
```

An 8-bit input data value is first encoded into a 12-bit Hamming codeword. The resulting 12-bit codeword is then transmitted as a single burst.

### Receive Path

The receive datapath operates as:

```text
UART RX
   │
   ▼
Receiver
   │
   ▼
12-bit Received Codeword
   │
   ▼
Hamming Decoder
   │
   ▼
Corrected 8-bit Data
   │
   ▼
RX FIFO / RBR
   │
   ▼
CPU
```

The decoder reconstructs the original 8-bit data and performs error detection/correction before the data is made available to the CPU.

---

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

---

## 🧱 Main RTL Modules

### `uart_16550.v`

Top-level UART module integrating the complete UART and ECC datapath.

It connects:

* UART register interface
* Baud-rate generator
* TX FIFO
* RX FIFO
* UART transmitter
* UART receiver
* Hamming encoder
* Hamming decoder
* Interrupt logic

This is the main **DUT (Device Under Test)** used by the simulation testbench.

---

### `registers.v`

Implements the UART register interface and provides access to UART configuration, control, and status registers.

---

### `baud_rate_generator.v`

Generates the timing signals required by the transmitter and receiver.

The module supports configurable baud-rate operation and provides the timing required for **16× receiver oversampling**.

---

### `fifo.v`

Generic FIFO implementation used for buffering UART transmit and receive data.

The FIFO module is instantiated for both:

* TX data buffering
* RX data buffering

---

### `tx.v`

Implements the UART transmitter using an FSM-based architecture.

The transmitter handles serial transmission according to the configured UART parameters and receives the encoded 12-bit data from the ECC datapath.

---

### `rx.v`

Implements the UART receiver using an FSM-based architecture.

The receiver uses the baud-rate timing and 16× oversampling mechanism to reconstruct incoming serial data before passing it to the Hamming decoder.

---

### `hamming_encoder.v`

Implements the Hamming encoding operation.

```text
8-bit input
    ↓
Hamming Encoder
    ↓
12-bit encoded output
```

This module is instantiated in the transmit datapath.

---

### `hamming_decoder.v`

Implements Hamming decoding and error correction.

```text
12-bit received input
        ↓
Hamming Decoder
        ↓
8-bit corrected output
```

The decoder also generates the syndrome and error status signals.

---

## 🧪 Simulation Testbench

The project includes a dedicated simulation testbench:

```text
testbench.v
```

The testbench instantiates and verifies:

```text
uart_16550.v
```

The simulation testbench is used to verify the functionality of the UART 16550 core and its integrated Hamming ECC datapath.

The testbench includes tests for:

### Test 1: Register Access

Verifies read/write functionality of UART registers such as:

* SCR
* LCR

### Test 2: Baud Rate Configuration

Programs and verifies the baud-rate divisor through:

* DLL
* DLM

### Test 3: Transmission

Writes data into the UART transmit interface and verifies that the UART completes transmission successfully.

### Test 4: Reception

Provides serial input to the UART receiver and verifies that:

* Data is received.
* The RX status is updated.
* The Hamming decoder reconstructs the original data.
* The expected 8-bit data is available at the receiver interface.

The simulation environment is intended specifically for **RTL verification of `uart_16550.v`**.

---

## 🖥️ FPGA Tester

The project also includes an FPGA tester module:

```text
fpga_tester.v
```

Unlike the simulation testbench, which uses simulation-specific constructs to drive and verify the UART, the FPGA tester is designed to test the UART on **actual FPGA hardware**.

The FPGA tester generates test data using a **counter** and feeds this data into the UART.

The basic testing flow is:

```text
Counter
   │
   ▼
Test Data
   │
   ▼
UART 16550
   │
   ├── Hamming Encoder
   │
   ├── UART TX
   │
   ├── UART RX
   │
   └── Hamming Decoder
   │
   ▼
Received Data
```

This provides a hardware-level verification environment for the UART and ECC implementation.

The FPGA tester is therefore separate from the RTL simulation testbench:

```text
testbench.v
    → Simulation of uart_16550.v

fpga_tester.v
    → Hardware testing of uart_16550.v on FPGA
```

---

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
* RTL Simulation
* FPGA Synthesis
* FPGA Implementation
* FPGA Hardware Testing

---

## 📌 Project Summary

This project extends a conventional UART 16550 RTL implementation by integrating a **Hamming (12,8) error-correction mechanism** directly into the transmit and receive datapaths.

The design accepts 8-bit data, encodes it into a 12-bit Hamming codeword for transmission, and decodes the received 12-bit codeword back into corrected 8-bit data.

The project provides both:

* **`testbench.v`** for simulation and verification of `uart_16550.v`
* **`fpga_tester.v`** for testing the UART on FPGA hardware using counter-generated data

The project therefore combines:

```text
UART 16550
     +
Hamming ECC
     +
Verilog RTL
     +
RTL Simulation
     +
FPGA Hardware Testing
```

making it a practical study of reliable serial communication, error-correcting codes, and digital hardware implementation.

---

## 🤝 Contributions

Contributions, suggestions, and improvements are welcome.

Feel free to fork the repository, open an issue, or submit a pull request.
