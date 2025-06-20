`timescale 1ns / 1ps

module ID_pipe_stage(
    input  clk, reset,
    input  [9:0] pc_plus4,
    input  [31:0] instr,
    input  mem_wb_reg_write,
    input  [4:0] mem_wb_write_reg_addr,
    input  [31:0] mem_wb_write_back_data,
    input  Data_Hazard,
    input  Control_Hazard,
    output [31:0] reg1, reg2,
    output [31:0] imm_value,
    output [9:0] branch_address,
    output [9:0] jump_address,   
    output branch_taken,
    output [4:0] destination_reg, 
    output mem_to_reg,
    output [1:0] alu_op,
    output mem_read,  
    output mem_write,
    output alu_src,
    output reg_write,
    output jump
);

    // Internal wires
    wire control_reg_dst, control_branch;
    wire hazard_selector;
    wire temp_mem_to_reg, temp_mem_read, temp_mem_write, temp_alu_src, temp_reg_write;
    wire [31:0] temp_reg1, temp_reg2, temp_imm_value;
    wire [1:0] temp_alu_op;

    // Control logic
    control controller(
        .reset(reset),
        .opcode(instr[31:26]),
        .reg_dst(control_reg_dst),
        .mem_to_reg(temp_mem_to_reg),
        .alu_op(temp_alu_op),
        .mem_read(temp_mem_read),
        .mem_write(temp_mem_write),
        .alu_src(temp_alu_src),
        .reg_write(temp_reg_write),
        .branch(control_branch),
        .jump(jump)
    );

    // Register file
    register_file rf(
        .clk(clk),
        .reset(reset),
        .reg_write_en(mem_wb_reg_write),
        .reg_write_dest(mem_wb_write_reg_addr),
        .reg_write_data(mem_wb_write_back_data),
        .reg_read_addr_1(instr[25:21]),
        .reg_read_addr_2(instr[20:16]),
        .reg_read_data_1(temp_reg1),
        .reg_read_data_2(temp_reg2)
    );

    // Destination register MUX
    mux2 #(.mux_width(5)) dest_mux(
        .a(instr[20:16]),
        .b(instr[15:11]),
        .sel(control_reg_dst),
        .y(destination_reg)
    );

    // Immediate value sign extension
    sign_extend imm_extender(
        .sign_ex_in(instr[15:0]),
        .sign_ex_out(temp_imm_value)
    );

    // MUX for control signals
    mux2 #(.mux_width(1)) mem_to_reg_mux(
        .a(temp_mem_to_reg),
        .b(1'b0),
        .sel(hazard_selector),
        .y(mem_to_reg)
    );

    mux2 #(.mux_width(2)) alu_op_mux(
        .a(temp_alu_op),
        .b(2'b0),
        .sel(hazard_selector),
        .y(alu_op)
    );

    mux2 #(.mux_width(1)) mem_read_mux(
        .a(temp_mem_read),
        .b(1'b0),
        .sel(hazard_selector),
        .y(mem_read)
    );

    mux2 #(.mux_width(1)) mem_write_mux(
        .a(temp_mem_write),
        .b(1'b0),
        .sel(hazard_selector),
        .y(mem_write)
    );

    mux2 #(.mux_width(1)) alu_src_mux(
        .a(temp_alu_src),
        .b(1'b0),
        .sel(hazard_selector),
        .y(alu_src)
    );

    mux2 #(.mux_width(1)) reg_write_mux(
        .a(temp_reg_write),
        .b(1'b0),
        .sel(hazard_selector),
        .y(reg_write)
    );

    // Outputs and calculations
    assign reg1 = temp_reg1;
    assign reg2 = temp_reg2;
    assign imm_value = temp_imm_value;
    assign jump_address = instr[25:0] << 2;
    assign branch_taken = control_branch & ((reg1 ^ reg2) == 32'd0) ? 1'b1 : 1'b0;
    assign branch_address = (temp_imm_value << 2) + pc_plus4;
    assign hazard_selector = ~(Data_Hazard) | Control_Hazard;

endmodule
