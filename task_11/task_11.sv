`timescale 1ns / 1ps
module task_11 #(
    parameter int TASK_INPUT_WIDTH  = 8,
    parameter int TASK_OUTPUT_WIDTH = 8,
    parameter int INPUT_STREAMS     = 1,
    parameter int OUTPUT_STREAMS    = 1

) (
    input i_clk,
    input i_rst,
    input [TASK_INPUT_WIDTH-1:0] i_data,
    input i_valid,
    input i_first,
    input i_last,
    output [TASK_OUTPUT_WIDTH-1:0] o_data,
    output o_valid,
    output o_last
);

  logic [6:0] c;
  logic [2:0] syndrome;
  logic [6:0] corrected;
  logic [3:0] data_bits;

  logic [TASK_OUTPUT_WIDTH-1:0] r_data;
  logic r_valid;
  logic r_last;

  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      r_data  <= 0;
      r_valid <= 0;
      r_last  <= 0;
    end else begin
      r_valid <= i_valid;
      r_last  <= i_last;

      if (i_valid) begin
        c = i_data[6:0];

        syndrome[0] = c[0] ^ c[2] ^ c[4] ^ c[6]; 
        syndrome[1] = c[1] ^ c[2] ^ c[5] ^ c[6];
        syndrome[2] = c[3] ^ c[4] ^ c[5] ^ c[6];

        corrected = c;
        if (syndrome != 3'b000) begin
          corrected[syndrome - 1] = ~corrected[syndrome - 1];
        end

        r_data <= {1'b0, corrected};
      end
    end
  end

  assign o_data  = r_data;
  assign o_valid = r_valid;
  assign o_last  = r_last;

endmodule
