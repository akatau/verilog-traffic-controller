# Verilog Traffic Light Controller

A Verilog implementation of a traffic light control system for an intersection of two one-way streets (North and East).

## Project Overview

The controller manages traffic flow based on two sensor inputs. It implements a Finite State Machine (FSM) to handle timing requirements and sensor logic. The system prioritizes efficiency: it will hold a green light indefinitely if there is no traffic on the cross-street, but will cycle fairly if traffic is detected in both directions.

### Logic Requirements
*   **Default State:** North Green.
*   **Green Duration:** Minimum of 30 seconds.
*   **Yellow Duration:** 5 seconds.
*   **Sensor Logic:**
    *   If no cars are waiting, stay Green in the current direction.
    *   If cars are detected in both directions, cycle through N-Green $\rightarrow$ Yellow $\rightarrow$ E-Green $\rightarrow$ Yellow.

## Hardware & Pin Mapping

The design targets an FPGA board using the following I/O:

| Port | Direction | Description |
| :--- | :--- | :--- |
| `CLOCK_50` | Input | 50MHz System Clock |
| `SW[0]` | Input | North Road Sensor (1 = Car present) |
| `SW[1]` | Input | East Road Sensor (1 = Car present) |
| `KEY[0]` | Input | System Reset (Active Low) |
| `LED_N[2:0]` | Output | North Lights (Bit 2: Red, 1: Yel, 0: Grn) |
| `LED_E[2:0]` | Output | East Lights (Bit 2: Red, 1: Yel, 0: Grn) |
| `HEX0` / `HEX1` | Output | *Reserved for 7-segment display* |

## Finite State Machine (FSM)

The controller uses a 4-state FSM:

1.  **State 0 (North Green):** North flows, East is Red. Checks `SW[1]` after 30s.
2.  **State 1 (Transition):** Both lights Yellow (5s).
3.  **State 2 (East Green):** East flows, North is Red. Checks `SW[0]` after 30s.
4.  **State 3 (Transition):** Both lights Yellow (5s).

## ⏱Timing Implementation

Because the FPGA runs at 50MHz, a 30-second timer requires counting 1.5 billion clock cycles.
*   **Pulse Generator:** A counter creates a `one_hz_enable` pulse every 50,000,000 clock cycles (1 second).
*   **Main Logic:** The FSM decrements a `timer_sec` register based on this 1-second pulse.

## Simulation

A testbench (`tb_traffic.v`) is included to verify the logic.

To avoid simulating 1.5 billion cycles, the testbench overrides the `CNT_MAX` parameter using `defparam`:
```verilog
// 1 second is simulated as 5 clock cycles
defparam dut.CNT_MAX = 5; 
```
This allows the verification of the 30-second hold times and state transitions in microseconds rather than minutes.

### How to Run
1.  Open the files in ModelSim, Questasim, or Vivado.
2.  Compile `traffic_light.v` and `tb_traffic.v`.
3.  Run the simulation.
4.  Observe `led_n` and `led_e` waveforms reacting to `sw` changes.

## 📜 License
This project is open source. Feel free to use it for educational purposes.
