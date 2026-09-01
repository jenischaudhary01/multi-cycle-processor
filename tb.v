`timescale 1ns/1ps
module tb;
    reg clk = 0;
    reg reset = 1;
    integer i;

    wire pcwrite, i_d, mem_write, ir_write, reg_write, mux_a, branch;
    wire [2:0] write_mux, mux_b, alu_control;
    wire [1:0] dest_mux, source_mux;
    wire [5:0] opcode, funct;

    control_unit cu(
        .clk(clk), .reset(reset),
        .opcode(opcode), .funct(funct),
        .pcwrite(pcwrite), .i_d(i_d), .mem_write(mem_write), .ir_write(ir_write),
        .write_mux(write_mux), .dest_mux(dest_mux), .reg_write(reg_write),
        .mux_a(mux_a), .mux_b(mux_b), .source_mux(source_mux),
        .branch(branch), .alu_control(alu_control)
    );

    datapath dp(
        .clk(clk), .reset(reset),
        .pcwrite(pcwrite), .i_d(i_d), .mem_write(mem_write), .ir_write(ir_write),
        .write_mux(write_mux), .dest_mux(dest_mux), .reg_write(reg_write),
        .mux_a(mux_a), .mux_b(mux_b), .source_mux(source_mux),
        .branch(branch), .alu_control(alu_control),
        .opcode(opcode), .funct(funct)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb);
    end

    initial begin
        reset = 1;
        repeat (2) @(posedge clk);
        reset = 0;

        repeat (300) @(posedge clk);

        for (i = 0; i < 32; i = i + 1) begin
            $display("$%0d = %0d", i, $signed(dp.a2.registers[i]));
        end
        $finish;
    end
endmodule