`timescale 1ns/1ps
`define opcode InstReg [31:27]
`define destreg InstReg [26:22]
`define srcreg1 InstReg [21:17]
`define modesel InstReg [16]
`define srcreg2 InstReg [15:11]
`define immed InstReg [15:0] 

`define movsgpr 5'b00000
`define mov     5'b00001
`define add     5'b00010
`define sub     5'b00011
`define mul     5'b00100

`define ror     5'b00101
`define rand    5'b00110
`define rxor    5'b00111
`define rxnor   5'b01000
`define rnand   5'b01001
`define rnor    5'b01010
`define rnot    5'b01011

`define storereg       5'b01101   //////store content of register in data memory
`define storedin       5'b01110   ////// store content of din bus in data memory
`define senddout       5'b01111   /////send data from DM to dout bus
`define sendreg        5'b10001   ////// send data from DM to register
 
`define jump           5'b10010  ////jump to address
`define jcarry         5'b10011  ////jump if carry
`define jnocarry       5'b10100
`define jsign          5'b10101  ////jump if sign
`define jnosign        5'b10110
`define jzero          5'b10111  //// jump if zero
`define jnozero        5'b11000
`define joverflow      5'b11001 ////jump if overflow
`define jnooverflow    5'b11010
 
//////////////////////////halt 
`define halt           5'b11011
 
 
 module top(
input clk,sys_rst,
input [15:0] din,
output reg [15:0] dout);

reg [31:0] inst_mem [15:0]; ////program memory
reg [15:0] data_mem [15:0]; ////data memory
 
reg [31:0] InstReg;

reg [15:0] GPReg [31:0];  // There are 32 Registers each 16 bits in length

reg [15:0] SGPR;
reg [31:0] mul_res;

reg sign=0, zero=0, overflow=0, carry=0;
reg [16:0] temp_sum;

reg jmp_flag = 0;
reg stop = 0;
 
  
task decode_inst();
begin
case(`opcode)

    `movsgpr: 
    begin
         GPReg[`destreg]=SGPR;
    end  
  
    `mov:
    begin
     if(`modesel)
         GPReg[`destreg]=`immed;
     else
         GPReg[`destreg]=GPReg[`srcreg1];
    end
    `add:
    begin 
     if(`modesel)
         GPReg[`destreg]=GPReg[`srcreg1]+`immed;
     else
         GPReg[`destreg]=GPReg[`srcreg1]+GPReg[`srcreg2];
    end
    `sub:
    begin 
     if(`modesel)
         GPReg[`destreg]=GPReg[`srcreg1]-`immed;
     else
         GPReg[`destreg]=GPReg[`srcreg1]-GPReg[`srcreg2];
    end
    
   `mul:
    begin 
     if(`modesel)
         mul_res=GPReg[`srcreg1]*`immed;
     else
         mul_res=GPReg[`srcreg1]*GPReg[`srcreg2];
     GPReg[`destreg]= mul_res[15:0];
         SGPR       = mul_res[31:16];
    end     
   `ror:
    begin 
     if(`modesel)
         GPReg[`destreg]=GPReg[`srcreg1]|`immed;
     else
         GPReg[`destreg]=GPReg[`srcreg1]|GPReg[`srcreg2];
    end
   `rand:
    begin 
     if(`modesel)
         GPReg[`destreg]=GPReg[`srcreg1]&`immed;
     else
         GPReg[`destreg]=GPReg[`srcreg1]&GPReg[`srcreg2];
    end  
   `rxor:
    begin 
     if(`modesel)
         GPReg[`destreg]=GPReg[`srcreg1]^`immed;
     else
         GPReg[`destreg]=GPReg[`srcreg1]^GPReg[`srcreg2];
    end
   `rxnor:
    begin 
     if(`modesel)
         GPReg[`destreg]=~(GPReg[`srcreg1]^`immed);
     else
         GPReg[`destreg]=~(GPReg[`srcreg1]|GPReg[`srcreg2]);
    end  
   `rnand:
    begin 
     if(`modesel)
         GPReg[`destreg]=~(GPReg[`srcreg1]&`immed);
     else
         GPReg[`destreg]=~(GPReg[`srcreg1]&GPReg[`srcreg2]);
    end
   `rnor:
    begin 
     if(`modesel)
         GPReg[`destreg]=~(GPReg[`srcreg1]|`immed);
     else
         GPReg[`destreg]=~(GPReg[`srcreg1]|GPReg[`srcreg2]);
    end
   `rnot:
    begin 
     if(`modesel)
         GPReg[`destreg]=~`immed;
     else
         GPReg[`destreg]=~GPReg[`srcreg1];
    end
   `storedin: 
    begin
         data_mem[`immed] = din;
    end

`storereg:
  begin
   data_mem[`immed] = GPReg[`srcreg1];
  end

`senddout: 
 begin
   dout  = data_mem[`immed]; 
 end
 
`sendreg:
 begin
  GPReg[`destreg] =  data_mem[`srcreg1];
 end
 
 `jump: 
 begin
 jmp_flag = 1'b1;
 end
 
`jcarry: 
  begin
  if(carry == 1'b1)
     jmp_flag = 1'b1;
   else
     jmp_flag = 1'b0; 
    end
 
`jsign:
  begin
  if(sign == 1'b1)
     jmp_flag = 1'b1;
   else
     jmp_flag = 1'b0; 
   end
 
`jzero:
  begin
  if(zero == 1'b1)
     jmp_flag = 1'b1;
   else
     jmp_flag = 1'b0; 
   end
 
 
`joverflow: 
   begin
  if(overflow == 1'b1)
     jmp_flag = 1'b1;
   else
     jmp_flag = 1'b0; 
   end
 
`jnocarry:
   begin
  if(carry == 1'b0)
     jmp_flag = 1'b1;
   else
     jmp_flag = 1'b0; 
  end
 
`jnosign: 
  begin
  if(sign == 1'b0)
     jmp_flag = 1'b1;
   else
     jmp_flag = 1'b0; 
  end
 
`jnozero:
  begin
  if(zero == 1'b0)
     jmp_flag = 1'b1;
   else
     jmp_flag = 1'b0; 
  end
 
 
`jnooverflow: 
  begin
  if(overflow == 1'b0)
     jmp_flag = 1'b1;
   else
     jmp_flag = 1'b0; 
  end
 
////////////////////////////////////////////////////////////
`halt :
   begin
  stop = 1'b1;
  end
 
endcase
end
endtask
    

//always@(*)  //Order Doesn't Matter:Since always blocks execute in parallel, their order in the source code does not matter.
task decode_condflag();
begin
   if(`opcode==`mul)
      sign = SGPR[15];
   else 
      sign = GPReg[`destreg][15];   
   if (`opcode==`add) 
    begin
      if(`modesel)
       begin 
       temp_sum=GPReg[`srcreg1]+`immed;
       carry=temp_sum[16];
       end
      else
        begin
        temp_sum=GPReg[`srcreg1]+GPReg[`srcreg2];
        carry=temp_sum[16];
        end
      
    end
   if(`opcode==`mul)
      zero = ~((SGPR)|(|GPReg[`destreg]));
   else 
      zero = ~(|GPReg[`destreg]);
   if(`opcode == `add)
     begin
       if(`modesel)
         overflow = ( (~GPReg[`srcreg1][15] & ~InstReg[15] & GPReg[`destreg][15] ) | (GPReg[`srcreg1][15] & InstReg[15] & ~GPReg[`destreg][15]) );
       else
         overflow = ( (~GPReg[`srcreg1][15] & ~GPReg[`srcreg2][15] & GPReg[`destreg][15]) | (GPReg[`srcreg1][15] & GPReg[`srcreg1][15] & ~GPReg[`destreg][15]));
     end
  else if(`opcode == `sub)
    begin
       if(`modesel) //InstReg[15] denotes MSB of immediate
         overflow = ( (~GPReg[`srcreg1][15] & InstReg[15] & GPReg[`destreg][15] ) | (GPReg[`srcreg1][15] & ~InstReg[15] & ~GPReg[`destreg][15]) );
       else
         overflow = ( (~GPReg[`srcreg1][15] & GPReg[`srcreg2][15] & GPReg[`destreg][15]) | (GPReg[`srcreg1][15] & ~GPReg[`srcreg2][15] & ~GPReg[`destreg][15]));
    end 


end
endtask
initial begin
$readmemb("inst_data.mem",inst_mem);
end
 
////////////////////////////////////////////////////
//////////reading instructions one after another
reg [2:0] count = 0;
integer PC = 0;

always@(posedge clk)
begin
  if(sys_rst)
   begin
     count <= 0;
     PC    <= 0;
   end
   else 
   begin
     if(count < 4)
     begin
     count <= count + 1;
     end
     else
     begin
     count <= 0;
     PC    <= PC + 1;
     end
 end
end

////////////////////////////////////////////////////
/////////reading instructions 

always@(*)
begin
if(sys_rst == 1'b1)
IR = 0;
else
begin
IR = inst_mem[PC];
decode_inst();
decode_condflag();
end
end

////////////////////////////////////////////////////
////////////////////////////////// fsm states
parameter idle = 0, fetch_inst = 1, dec_exec_inst = 2, next_inst = 3, sense_halt = 4, delay_next_inst = 5;
//////idle : check reset state
///// fetch_inst : load instrcution from Program memory
///// dec_exec_inst : execute instruction + update condition flag
///// next_inst : next instruction to be fetched
reg [2:0] state = idle, next_state = idle;
////////////////////////////////// fsm states
 
///////////////////reset decoder
always@(posedge clk)
begin
 if(sys_rst)
   state <= idle;
 else
   state <= next_state; 
end
 
 
//////////////////next state decoder + output decoder
 
always@(*)
begin
  case(state)
   idle: begin
     InstReg         = 32'h0;
     PC         = 0;
     next_state = fetch_inst;
   end
 
  fetch_inst: begin
    InstReg          =  inst_mem[PC];   
    next_state  = dec_exec_inst;
  end
  
  dec_exec_inst: begin
    decode_inst();
    decode_condflag();
    next_state  = delay_next_inst;   
  end
  
  
  delay_next_inst:begin
  if(count < 4)
       next_state  = delay_next_inst;       
     else
       next_state  = next_inst;
  end
  
  next_inst: begin
      next_state = sense_halt;
      if(jmp_flag == 1'b1)
        PC = `immed;
      else
        PC = PC + 1;
  end
  
  
 sense_halt: begin
    if(stop == 1'b0)
      next_state = fetch_inst;
    else if(sys_rst == 1'b1)
      next_state = idle;
    else
      next_state = sense_halt;
 end
  
  default : next_state = idle;
  
  endcase
  
end
 
 
////////////////////////////////// count update 
 
always@(posedge clk)
begin
case(state)
 
 idle : begin
    count <= 0;
 end
 
 fetch_inst: begin
   count <= 0;
 end
 
 dec_exec_inst : begin
   count <= 0;    
 end  
 
 delay_next_inst: begin
   count  <= count + 1;
 end
 
  next_inst : begin
    count <= 0;
 end
 
  sense_halt : begin
    count <= 0;
 end
 
 default : count <= 0;
  
endcase
end
  
endmodule
