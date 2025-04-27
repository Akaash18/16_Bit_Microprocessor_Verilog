**Instruction Format & Decoding:**

  Instructions are 32-bit wide and broken down using macros (e.g., opcode, destreg, srcreg1, etc.)

  Supports both register and immediate mode operations via a modesel bit.

**Registers and Memories:**

  32 General Purpose Registers (GPRs), each 16-bit.

  Special-purpose register SGPR stores the upper 16 bits of multiplication.

  16-entry instruction and data memory, initialized using $readmemb.

**ALU Operations:**

  Includes add, sub, mul, bitwise operations (and, or, xor, etc.)
  
  Multiplication returns a 32-bit result, split between GPReg and SGPR.

**Data Movement:**
  Supports moving data between register, memory, input bus din, and output bus dout.
  
**Control Flow Instructions:**  
  Jump instructions like jump, jcarry, jzero, joverflow, etc., based on condition flags.

**Condition Flags:**
  Evaluates sign, zero, carry, and overflow in a dedicated task decode_condflag().

**FSM (Finite State Machine):**
  Consists of 6 states:
  
  **idle**: Wait for reset release
  
  **fetch_inst**: Load instruction from memory
  
  **dec_exec_inst**: Decode and execute
  
  **delay_next_inst**: Add instruction delay
  
  **next_inst**: Calculate next PC (with jump logic)
  
  **sense_halt**: Halt detection
