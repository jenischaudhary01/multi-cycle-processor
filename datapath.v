module datapath(
    input clk,
    input reset,
    input pcwrite,
    input i_d,
    input mem_write,
    input ir_write,
    input [2:0]write_mux,
    input [1:0]dest_mux,
    input reg_write,
    input mux_a,
    input [2:0]mux_b,
    input [1:0]source_mux,
    input branch,
    input [2:0]alu_control,
    output [5:0]opcode,
    output [5:0]funct
);
reg [31:0] pc,next_pc;
wire [31:0]data_in;
wire [31:0]data_out;
reg [31:0] instruction;
reg [31:0] data_reg;
reg [4:0]write_port;
reg [31:0]write_data;
wire [31:0]read_data1;
wire [31:0]read_data2;
reg [31:0] srca;
reg [31:0] srcb;
reg [31:0] srca2;
reg [31:0] srcb2;
wire [31:0] sign_extended;
wire  [31:0] zero_sign_extended;
wire [31:0] alu_out;
reg [31:0] alu_reg;
wire [31:0] sll;
wire [31:0] srl;
wire [31:0] lui;
wire  pc_ena;
wire  bcond;
assign sign_extended={{16{instruction[15]}},instruction[15:0]};
assign zero_sign_extended={{16{1'b0}},instruction[15:0]};
always @(posedge clk) begin
  if(reset) begin
    pc<=32'd0;
  end
  else begin
    if(pc_ena) begin
      pc<=next_pc;
    end
    else begin
      pc<=pc;
    end
  end
end
assign data_in=(i_d)?alu_reg:pc;
data a1(clk,data_in,mem_write,srcb,data_out);
always @(posedge clk) begin
  if(reset) begin
    instruction<=32'd0;
  end
  else begin
    if(ir_write) begin
      instruction<=data_out;
    end
    else begin
      instruction<=instruction;
    end
  end
end
always @(posedge clk) begin
    if(reset) begin
      data_reg<=32'd0;
    end
    else begin
  data_reg<=data_out;
    end
end
always @(*) begin
  case(dest_mux)
  2'b01: write_port=instruction[20:16];
  2'b10: write_port=5'b11111;
  default : write_port=instruction[15:11];
  endcase
end
always @(*) begin
  case(write_mux)
  3'd1: write_data=data_reg;
  3'd2: write_data=pc;
  3'd3: write_data=sll;
  3'd4: write_data=srl;
  3'd5: write_data=lui;
  default : write_data=alu_reg;
  endcase
end
reg_file a2(clk,reset,reg_write,instruction[25:21],instruction[20:16],write_port,write_data,read_data1,read_data2);
always @(posedge clk) begin
    if(reset) begin
      srca<=32'd0;
      srcb<=32'd0;
    end
    else begin
      srca<=read_data1;
      srcb<=read_data2;
    end
end
always @(*) begin
  case(mux_a)
  1'b1: srca2=pc;
  default : srca2=srca;
  endcase
end
always @(*) begin
  case(mux_b)
3'd1: srcb2=32'd4;
3'd2: srcb2=32'd0;
3'd3: srcb2=sign_extended;
3'd4: srcb2=zero_sign_extended;
3'd5: srcb2=sign_extended<<2;
default : srcb2=srcb;
  endcase
end
alu a3(alu_control,srca2,srcb2,alu_out);
always @(posedge clk) begin
  if(reset) begin
    alu_reg<=32'd0;
  end
  else begin
    alu_reg<=alu_out;
  end
end
assign sll=srcb2<<instruction[10:6];
assign srl=srcb2>>instruction[10:6];
assign lui={instruction[15:0],{16{1'b0}}};
always @(*) begin
  case(source_mux)
  3'd1: next_pc=alu_reg;
  3'd2: next_pc=read_data1;
  3'd3: next_pc={pc[31:28],instruction[25:0],2'b00};
  default : next_pc=alu_out;
  endcase
end
assign bcond = ((instruction[31:26] == 6'b000100) && (alu_out == 32'd0))                           
            || ((instruction[31:26] == 6'b000101) && (alu_out != 32'd0))                             
            || ((instruction[31:26] == 6'b000110) && ($signed(srca) <= 0))                          
            || ((instruction[31:26] == 6'b000111) && ($signed(srca) > 0))                           
            || ((instruction[31:26] == 6'b000001) && (instruction[20:16] == 5'b00000) && ($signed(srca) < 0))   
            || ((instruction[31:26] == 6'b000001) && (instruction[20:16] == 5'b00001) && ($signed(srca) >= 0)); 
assign opcode=instruction[31:26];
assign funct=instruction[5:0];
assign pc_ena=pcwrite|(bcond&&branch);
endmodule