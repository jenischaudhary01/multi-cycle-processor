module data(
    input clk,
input [31:0] addr,
input mem_write,
input [31:0] write_data,
output [31:0] data_out
);
reg [31:0] memory [255:0];
initial begin
  $readmemh("instruction.hex",memory);
end
always @(posedge clk) begin
  if(mem_write) begin
    memory[addr[9:2]]<=write_data;
  end
end
assign data_out=memory[addr[9:2]];
endmodule