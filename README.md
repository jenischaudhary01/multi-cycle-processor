# Multi-Cycle Processor (MIPS-based)

A **multi-cycle MIPS processor** implemented in Verilog. The design breaks instruction execution into multiple clock cycles (Fetch → Decode → Execute → Memory → Writeback), controlled by a finite state machine (FSM), instead of executing an entire instruction in a single clock cycle.

This project includes the datapath, control unit, ALU, register file, a simple two-pass assembler (written in C) to convert MIPS assembly into machine code, and a testbench to simulate the whole processor.

---

## Features

- Multi-cycle FSM-based control unit (variable number of cycles per instruction)
- Supports R-type, I-type, and J-type MIPS instructions
- Custom two-pass assembler (`assembler.c`) that converts `.asm` files into a `.hex` instruction memory image
- Self-checking testbench that runs a program and dumps final register values
- Waveform (`.vcd`) generation for debugging in GTKWave

---

## Repository Structure

| File | Description |
|---|---|
| `datapath.v` | The datapath: PC, instruction register, register file interface, ALU interface, sign-extension, muxes for source/destination selection |
| `control.v` | FSM-based control unit that generates control signals for every clock cycle of an instruction |
| `alu.v` | Arithmetic Logic Unit used by the datapath |
| `register_file.v` | 32 x 32-bit general purpose register file |
| `data.v` | Unified instruction/data memory module |
| `tb.v` | Testbench — instantiates control unit + datapath, applies clock/reset, runs simulation, and prints final register contents |
| `assembler.c` | A simple C assembler that converts MIPS assembly (`myprogram1.asm`) into machine code (`instruction.hex`) |
| `myprogram1.asm` | Example MIPS assembly program |
| `instruction.hex` | Machine code generated from `myprogram1.asm`, loaded into instruction memory for simulation |

---

## Architecture Overview

The processor follows the classic **Hennessy & Patterson multi-cycle MIPS** design, where each instruction takes a different number of clock cycles depending on its type:

| Stage | Cycles used |
|---|---|
| Fetch | All instructions |
| Decode | All instructions |
| Execute | R-type / I-type / Branch / Jump |
| Memory Access | Only `lw` / `sw` |
| Writeback | R-type / I-type / `lw` / `lui` / `jal` |

The FSM (in `control.v`) moves between these states based on the opcode/funct field of the currently fetched instruction, asserting the appropriate control signals (`pcwrite`, `ir_write`, `reg_write`, `mem_write`, ALU control, mux selects, etc.) on each state.

### Supported Instructions

**R-type:** `add`, `sub`, `and`, `or`, `slt`, `jr`, `sll`, `srl`

**I-type:** `addi`, `andi`, `ori`, `slti`, `lui`, `lw`, `sw`, `beq`, `bne`, `blez`, `bgtz`, `bltz`, `bgez`

**J-type:** `j`, `jal`

---

## Example Program

`myprogram1.asm` computes the sum of the numbers 1 through 5 using a loop, and stores the result in `$5`.

```asm
addi $1, $0, 0      # sum = 0
addi $2, $0, 1      # counter = 1
addi $3, $0, 5      # limit = 5

loop:
add  $1, $1, $2     # sum += counter
addi $2, $2, 1      # counter++
slt  $4, $3, $2     # $4 = (limit < counter) ? 1 : 0
beq  $4, $0, loop   # loop while counter <= limit

addi $5, $1, 0      # $5 = sum  (expected result: 15)

done:
j done              # halt (infinite loop)
```

Expected result after simulation: **`$5 = 15`** (1 + 2 + 3 + 4 + 5).

This same program and expected output can be used to verify **both** the single-cycle and multi-cycle versions of this MIPS processor — the instruction set, register conventions, and final result are identical between the two designs. Only the internal timing (number of clock cycles per instruction) and control-unit implementation differ.

---

## How to Run

### 1. Assemble the program

Compile and run the assembler to convert `myprogram1.asm` into `instruction.hex`:

```bash
gcc assembler.c -o assembler
./assembler
```

This reads `myprogram1.asm` and produces `instruction.hex`, which is loaded by `data.v` into instruction/data memory.

### 2. Simulate the processor

Using Icarus Verilog (or any Verilog simulator of your choice):

```bash
iverilog -o sim tb.v datapath.v control.v alu.v register_file.v data.v
vvp sim
```

### 3. View results

The testbench applies reset for 2 clock cycles, runs the simulation for 300 clock cycles, and then prints the contents of all 32 registers:

```
$0 = 0
$1 = 15
$2 = 6
$3 = 5
$4 = 1
$5 = 15
...
```

### 4. (Optional) View waveforms

The testbench dumps a waveform file (`wave.vcd`) that can be viewed with [GTKWave](http://gtkwave.sourceforge.net/):

```bash
gtkwave wave.vcd
```

---

## Notes

- The register file, ALU, and memory modules are shared/reusable components — the same modules can back either a single-cycle or multi-cycle implementation of this MIPS core.
- The multi-cycle design trades a longer, variable latency per instruction for smaller, reusable hardware (a single ALU and single memory port shared across fetch/execute/memory stages), unlike a single-cycle design which needs separate hardware for each stage to finish everything in one clock.
- `alu_control` encoding, mux selects, and FSM states are documented inline as parameters/comments in `control.v`.
