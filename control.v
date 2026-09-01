module control_unit (
    input  wire        clk,
    input  wire        reset,
    input  wire [5:0]  opcode,
    input  wire [5:0]  funct,
    output reg         pcwrite,
    output reg         i_d,
    output reg         mem_write,
    output reg         ir_write,
    output reg  [2:0]  write_mux,
    output reg  [1:0]  dest_mux,
    output reg         reg_write,
    output reg         mux_a,
    output reg  [2:0]  mux_b,
    output reg  [1:0]  source_mux,
    output reg         branch,
    output reg  [2:0]  alu_control
);

    parameter FETCH       = 4'd0;
    parameter DECODE      = 4'd1;
    parameter R_EXEC      = 4'd2;
    parameter R_WB        = 4'd3;
    parameter I_EXEC      = 4'd4;
    parameter I_WB        = 4'd5;
    parameter MEM_ADDR    = 4'd6;
    parameter MEM_READ    = 4'd7;
    parameter MEM_WRITE_S = 4'd8;
    parameter MEM_WB      = 4'd9;
    parameter BRANCH_S    = 4'd10;
    parameter JUMP_S      = 4'd11;
    parameter JAL_S       = 4'd12;
    parameter JR_S        = 4'd13;
    parameter LUI_WB      = 4'd14;

    reg [3:0] state, next_state;

    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= FETCH;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            FETCH: next_state = DECODE;

            DECODE: begin
                case (opcode)
                    6'b000000: begin
                        if (funct == 6'b001000)
                            next_state = JR_S;
                        else
                            next_state = R_EXEC;
                    end
                    6'b100011,
                    6'b101011: next_state = MEM_ADDR;
                    6'b001000, 6'b001001,
                    6'b001100,
                    6'b001101,
                    6'b001010: next_state = I_EXEC;
                    6'b001111: next_state = LUI_WB;
                    6'b000100, 6'b000101,
                    6'b000110, 6'b000111,
                    6'b000001: next_state = BRANCH_S;
                    6'b000010: next_state = JUMP_S;
                    6'b000011: next_state = JAL_S;
                    default:   next_state = FETCH;
                endcase
            end

            MEM_ADDR: begin
                if (opcode == 6'b100011)
                    next_state = MEM_READ;
                else
                    next_state = MEM_WRITE_S;
            end

            MEM_READ:    next_state = MEM_WB;
            MEM_WB:      next_state = FETCH;
            MEM_WRITE_S: next_state = FETCH;
            R_EXEC:      next_state = R_WB;
            R_WB:        next_state = FETCH;
            I_EXEC:      next_state = I_WB;
            I_WB:        next_state = FETCH;
            LUI_WB:      next_state = FETCH;
            BRANCH_S:    next_state = FETCH;
            JUMP_S:      next_state = FETCH;
            JAL_S:       next_state = FETCH;
            JR_S:        next_state = FETCH;
            default:     next_state = FETCH;
        endcase
    end

    always @(*) begin
        pcwrite     = 1'b0;
        i_d         = 1'b0;
        mem_write   = 1'b0;
        ir_write    = 1'b0;
        write_mux   = 3'd0;
        dest_mux    = 2'b00;
        reg_write   = 1'b0;
        mux_a       = 1'b0;
        mux_b       = 3'd0;
        source_mux  = 2'd0;
        branch      = 1'b0;
        alu_control = 3'd0;

        case (state)
            FETCH: begin
                i_d         = 1'b0;
                ir_write    = 1'b1;
                mux_a       = 1'b1;
                mux_b       = 3'd1;
                alu_control = 3'd0;
                source_mux  = 2'd0;
                pcwrite     = 1'b1;
            end

            DECODE: begin
                mux_a       = 1'b1;
                mux_b       = 3'd5;
                alu_control = 3'd0;
            end

            R_EXEC: begin
                mux_a = 1'b0;
                mux_b = 3'd0;
                case (funct)
                    6'b100000, 6'b100001: alu_control = 3'd0;
                    6'b100010, 6'b100011: alu_control = 3'd4;
                    6'b100100:            alu_control = 3'd1;
                    6'b100101:            alu_control = 3'd2;
                    6'b101010, 6'b101011: alu_control = 3'd7;
                    default:              alu_control = 3'd0;
                endcase
            end

            R_WB: begin
                dest_mux  = 2'b00;
                reg_write = 1'b1;
                case (funct)
                    6'b000000: write_mux = 3'd3;
                    6'b000010: write_mux = 3'd4;
                    default:   write_mux = 3'd0;
                endcase
            end

            I_EXEC: begin
                mux_a = 1'b0;
                case (opcode)
                    6'b001000, 6'b001001: begin
                        mux_b       = 3'd3;
                        alu_control = 3'd0;
                    end
                    6'b001100: begin
                        mux_b       = 3'd4;
                        alu_control = 3'd1;
                    end
                    6'b001101: begin
                        mux_b       = 3'd4;
                        alu_control = 3'd2;
                    end
                    6'b001010: begin
                        mux_b       = 3'd3;
                        alu_control = 3'd7;
                    end
                    default: begin
                        mux_b       = 3'd3;
                        alu_control = 3'd0;
                    end
                endcase
            end

            I_WB: begin
                dest_mux  = 2'b01;
                write_mux = 3'd0;
                reg_write = 1'b1;
            end

            MEM_ADDR: begin
                mux_a       = 1'b0;
                mux_b       = 3'd3;
                alu_control = 3'd0;
            end

            MEM_READ: begin
                i_d = 1'b1;
            end

            MEM_WB: begin
                dest_mux  = 2'b01;
                write_mux = 3'd1;
                reg_write = 1'b1;
            end

            MEM_WRITE_S: begin
                i_d       = 1'b1;
                mem_write = 1'b1;
            end

            LUI_WB: begin
                dest_mux  = 2'b01;
                write_mux = 3'd5;
                reg_write = 1'b1;
            end

            BRANCH_S: begin
                mux_a       = 1'b0;
                mux_b       = 3'd0;
                alu_control = 3'd4;
                source_mux  = 2'd1;
                branch      = 1'b1;
            end

            JUMP_S: begin
                source_mux = 2'd3;
                pcwrite    = 1'b1;
            end

            JAL_S: begin
                source_mux = 2'd3;
                pcwrite    = 1'b1;
                dest_mux   = 2'b10;
                write_mux  = 3'd2;
                reg_write  = 1'b1;
            end

            JR_S: begin
                source_mux = 2'd2;
                pcwrite    = 1'b1;
            end
        endcase
    end

endmodule