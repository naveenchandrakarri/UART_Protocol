# UART_Protocol

A configurable UART (Universal Asynchronous Receiver Transmitter) implemented in Verilog HDL and verified using a complete UVM (Universal Verification Methodology) based verification environment.

This project was developed to understand modern verification methodologies used in ASIC and FPGA design verification. The verification environment employs constrained-random stimulus generation, protocol-aware scoreboarding, SystemVerilog Assertions (SVA), and Functional Coverage to validate UART functionality across multiple configurations.

The UART supports configurable baud rates, variable data lengths, parity generation and checking, frame error detection, and parity error detection.

The verification environment includes:

* UVM 1.2 Testbench Architecture
* Constrained-Random Stimulus Generation
* Driver, Monitor, Agent, Environment and Test Components
* Scoreboard-Based Data Checking
* SystemVerilog Assertions (SVA)
* Functional Coverage Collection
* Coverage Report Generation

The design was successfully simulated and verified using UVM methodology. Assertions and functional coverage were used to ensure protocol correctness and measure verification completeness.

## UART Architecture Overview

The UART consists of the following modules:

* Baud Rate Generator
* UART Transmitter (TX)
* UART Receiver (RX)
* Parity Generator and Checker
* Frame Error Detection Logic

The design supports:

* Multiple baud rates
* Variable frame lengths
* Even parity
* Odd parity
* Parity disabled mode
* Frame error detection
* Parity error detection

## Supported Features

### Baud Rate Selection

The UART supports the following baud rates:

* 1200 bps
* 2400 bps
* 4800 bps
* 9600 bps
* 115200 bps
* 921600 bps

### Data Length Support

* 5-bit data
* 6-bit data
* 7-bit data
* 8-bit data

### Parity Modes

* No Parity
* Even Parity
* Odd Parity

### Error Detection

* Frame Error Detection
* Parity Error Detection

## Verification Environment

The verification environment was developed using UVM 1.2.

### Sequence Generator

Generates constrained-random UART transactions including:

* Random data patterns
* Random baud rates
* Random frame lengths
* Random parity configurations

### Driver

Drives randomized transactions onto the DUT interface and synchronizes stimulus using UART completion signals.

### Monitor

Observes DUT activity and collects transmitted and received UART transactions.

### Scoreboard

Performs end-to-end data checking by comparing transmitted data against received data for all supported UART configurations.

### Agent

Contains:

* Sequencer
* Driver
* Monitor

### Environment

Integrates:

* UART Agent
* Scoreboard
* Functional Coverage Collector

### Test

Executes constrained-random verification sequences and manages simulation control through UVM phases.

## SystemVerilog Assertions

Protocol-level assertions were implemented to verify UART behavior.

Assertions include:

### Configuration Assertions

* Valid baud rate selection
* Valid data length selection

### Protocol Assertions

* TX line remains high during idle state
* Parity-enabled transactions enter parity state
* UART transmission completes successfully
* Protocol timing and state transition checks

Assertions were used to automatically detect protocol violations during simulation.

## Functional Coverage

Functional coverage was implemented using UVM subscriber-based covergroups.

Coverage points include:

### Baud Rate Coverage

* 1200
* 2400
* 4800
* 9600
* 115200
* 921600

### Data Length Coverage

* 5-bit
* 6-bit
* 7-bit
* 8-bit

### Parity Coverage

* Parity Enabled
* Parity Disabled
* Even Parity
* Odd Parity

### Error Coverage

* Frame Error
* Parity Error

### Cross Coverage

* Baud Rate × Data Length
* Parity Enable × Parity Type

Coverage reports were generated using Riviera-Pro coverage databases and ACDB reporting utilities.

## Project Structure
```text
uart_uvm_verification/

├── rtl/
│   ├── uart.sv
│   ├── tx.sv
│   ├── rx.sv
│   └── clk_gen.sv
│
├── tb/
│   ├── interface.sv
│   ├── transaction.sv
│   ├── generator.sv
│   ├── driver.sv
│   ├── monitor.sv
│   ├── scoreboard.sv
│   ├── coverage.sv
│   ├── agent.sv
│   ├── env.sv
│   ├── test.sv
│   └── tb_top.sv
│
├── assertions/
│   └── uart_assertions.sv
│
├── reports/
│   ├── coverage_report.txt
│   └── assertion_summary.txt
│
└── run.do
```
## Verification Strategy

The UART was verified using:

* Directed testing
* Constrained-random testing
* Assertion-based verification
* Functional coverage analysis
* Scoreboard-based checking

Waveform analysis was used to verify:

* UART frame generation
* Start bit transmission
* Data bit transmission
* Parity generation and checking
* Stop bit generation
* Error detection logic
* TX/RX synchronization

## Tools Used

* Verilog HDL
* SystemVerilog
* UVM 1.2
* Riviera-PRO
* EDA Playground
* GTKWave

## Results

The project successfully demonstrates verification of a configurable UART using industry-standard verification techniques.

The verification environment successfully validates:

* UART transmission and reception
* Multiple baud rate configurations
* Variable frame lengths
* Even and odd parity operation
* Frame error detection
* Parity error detection
* Protocol compliance using assertions
* Verification completeness using functional coverage

The successful execution of constrained-random tests, assertion-based checks, and functional coverage collection confirms correct UART functionality across multiple operating configurations.
