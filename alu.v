module alu(
    input [2:0]aluop,
    input [31:0]read1,
    input [31:0]read2,
    output reg [31:0]w
);
always @(*) begin
  case(aluop) 
  3'd0: w=read1+read2;
  3'd1: w=read1&read2;
3'd2:w=read1|read2;
3'd4:w=read1-read2;
3'd5:w=read1&(~read2);
3'd6:w=read1|(~read2);
3'd7:w=($signed(read1)<$signed(read2))?32'd1:32'd0;
default:w=read1+read2;
  endcase
end
endmodule