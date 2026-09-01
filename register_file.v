module reg_file(
    input clk,
    input reset,
    input reg_write,
    input [4:0]read_port1,
    input [4:0]read_port2,
    input [4:0]write_port,
    input [31:0]write_data,
    output [31:0]read_data1,
    output [31:0]read_data2
);
reg [31:0]registers[31:0];
integer i;
always @(posedge clk) begin
    if(reset) begin
        for(i=0;i<32;i=i+1) begin
          registers[i]<=32'd0;
        end
    end
    else begin
      if(reg_write&&(write_port!=5'd0)) begin
        registers[write_port]<=write_data;
      end
    end
end
assign read_data1=(read_port1==5'd0)?32'd0:registers[read_port1];
assign read_data2=(read_port2==5'd0)?32'd0:registers[read_port2];
endmodule
