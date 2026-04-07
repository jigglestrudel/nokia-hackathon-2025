`timescale 1ns / 1ps
module task_1
#(
  parameter int TASK_INPUT_WIDTH = 16,
  parameter int TASK_OUTPUT_WIDTH = 16,
  parameter int INPUT_STREAMS     = 1,
  parameter int OUTPUT_STREAMS    = 1

)(
  input                               i_clk,
  input                               i_rst,

  input                               i_valid,
  input                               i_first,
  input                               i_last,
  input signed [TASK_INPUT_WIDTH-1:0] i_data,

  output reg                          o_valid,
  output reg                          o_last,
  output reg signed [TASK_OUTPUT_WIDTH-1:0] o_data
);

  reg signed [TASK_INPUT_WIDTH-1:0] max_value = -(1 <<< (TASK_INPUT_WIDTH - 1));
  reg ready = 0; 

  always @(posedge i_clk) begin
    
    if (i_rst) begin
      max_value <= -(1 <<< (TASK_INPUT_WIDTH - 1));
      o_data    <= 0;
      o_valid   <= 0;
      o_last    <= 0;
      ready     <= 0;
    end 
    else begin
      o_valid <= 0;
      o_last  <= 0;

      if (i_valid) begin
        if (i_first) begin
          max_value <= i_data;
        end 
        else begin
          if (i_data > max_value)
            max_value <= i_data;
        end

        if (i_last) begin
          ready <= 1;
        end
      end

      if (ready) begin
        ready <= 0;
        o_data  <= max_value;
        o_valid <= 1;
        o_last  <= 1;
      end
    end
  end

endmodule
