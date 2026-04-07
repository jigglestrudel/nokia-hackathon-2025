`timescale 1 ns / 1 ps
module task_7 #(
    parameter int TASK_INPUT_WIDTH  = 8,
    parameter int TASK_OUTPUT_WIDTH = 32,
    parameter int INPUT_STREAMS     = 9,
    parameter int OUTPUT_STREAMS    = 2
)(
    input i_clk,
    input i_rst,
    input i_valid,
    input i_last,
    input i_first,
    input signed [TASK_INPUT_WIDTH-1:0] i_data_A_0,
    input signed [TASK_INPUT_WIDTH-1:0] i_data_A_1,
    input signed [TASK_INPUT_WIDTH-1:0] i_data_A_2,
    input signed [TASK_INPUT_WIDTH-1:0] i_data_D_0,
    input signed [TASK_INPUT_WIDTH-1:0] i_data_D_1,
    input signed [TASK_INPUT_WIDTH-1:0] i_data_D_2,
    input signed [TASK_INPUT_WIDTH-1:0] i_data_B_0,
    input signed [TASK_INPUT_WIDTH-1:0] i_data_B_1,
    input signed [TASK_INPUT_WIDTH-1:0] i_data_B_2,
    output [TASK_OUTPUT_WIDTH-1:0] o_data_AB,
    output [TASK_OUTPUT_WIDTH-1:0] o_data_DB,
    output o_valid,
    output o_last
);
  
  logic [44:0] P = 0;
  logic is_valid = 0;

  logic is_last = 0;
  logic r_valid = 0;
  logic r_last = 0;
  logic [31:0] r_data_AB;
  logic [31:0] r_data_DB;

  
  always@(posedge i_clk) begin

    if (i_rst) begin
      r_valid <= 0;
      r_last <= 0;
      r_data_AB <= 0;
      r_data_DB <= 0;
      P <= 0;
    end
   
    if (i_valid || is_last) begin
      if (is_last) begin
        r_valid <= 1;
        r_last <= 1;
        is_valid <= 0;
        is_last <= 0;
      end
      if (i_last) begin
        is_last <= 1;
      end

      if (is_valid) begin
        r_valid <= 1;
        r_data_AB <= P[35:18] + P[17];
        r_data_DB <= P[17:0];
      end

      P <= (({i_data_A_0[7], i_data_A_0, 18'b000000000000000000} + { {18{i_data_D_0[7]}}, i_data_D_0 }) * ({ {10{i_data_B_0[7]}}, i_data_B_0}))
        + (({i_data_A_1[7], i_data_A_1, 18'b000000000000000000} + { {18{i_data_D_1[7]}}, i_data_D_1 }) * ({ {10{i_data_B_1[7]}}, i_data_B_1}))
        + (({i_data_A_2[7], i_data_A_2, 18'b000000000000000000} + { {18{i_data_D_2[7]}}, i_data_D_2 }) * ({ {10{i_data_B_2[7]}}, i_data_B_2}));

      is_valid <= 1;
    end
    else if (r_last) begin
      r_valid <= 0;
      r_last <= 0;
      is_valid <= 0;
    end
  end


  assign o_valid = r_valid;
  assign o_data_AB = r_data_AB;
  assign o_data_DB = r_data_DB;
  assign o_last = r_last;
  
endmodule
