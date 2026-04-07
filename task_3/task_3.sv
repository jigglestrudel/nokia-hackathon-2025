`timescale 1ns / 1ps
module task_3 #(
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

  logic [TASK_OUTPUT_WIDTH-1:0] r_data; // Just a dummy register. Replace with your code.
  logic r_valid; // Just a dummy register. Replace with your code.
  logic r_last; // Just a dummy register. Replace with your code.

  logic [7:0] matrix [4090:0][4090:0];
  logic [7:0] size_x, size_y;
  logic [7:0] index_x;
  logic [7:0] index_y;
  logic y_is_next;

  logic walking_ne;
  logic walking_sw;
  logic walked_right;
  logic walked_down;

  reg [2:0] state;
  localparam IDLE       = 3'b000;
  localparam READING    = 3'b001;
  localparam SEARCHING  = 3'b010;
  localparam ERROR      = 3'b011;
  localparam FOUND      = 3'b100;

  always@(posedge i_clk) begin
    if(i_rst) begin
      state <= READING;
      size_x <= 0;
      size_y <= 0;
      y_is_next <= 0;
      index_x <= 0;
      index_y <= 0;
      o_valid <= 0;
      o_last <= 0;
      o_data <= 0;
       walking_ne <= 1;
       walking_sw <= 0;
       walked_right <= 0;
       walked_down <= 0;
    end
    else begin

      case (state)
        READING: begin
          if (i_valid) begin
            if (i_first) begin
              size_x <= i_data;
              
              y_is_next <= 1;
            end
            else if (y_is_next) begin
              size_y <= i_data;
              y_is_next <= 0;
            end
            else if (i_last) begin
              // no idea what should happen here lmao
              // lets just put the data byte on the last spot or smth idk
              maze_map[size_y - 1][size_x-1] <= i_data;

              index_x <= 0;
              index_y <= 0;


              state <= SEARCHING;
            end
            else begin
              maze_map[index_y][index_x] <= i_data;
              
              index_x <= index_x + 1;
              if (index_x >= size_x - 1) begin
                index_x <= 0;
                index_y <= index_y + 1;
              end
            end
          end
        end
        IDLE: begin
          // sranie w banie
        end
        SEARCHING: begin

          if (index_x == size_x-1 && index_y == size_y - 1) begin
            write_out_index <= 0;
            state <= FOUND;
          end
          else begin
            if (index_y == 0 && walking_ne) begin
              walking_ne <= 0;
              walking_sw <= 1;
              // step right
              index_x <= index_x + 1;
            end
            else if (index_x == 0 && index_y != size_y - 1 && walking_sw) begin
              walking_ne <= 1;
              walked_down <= 1;

              index_y <= index_y + 1;
            end
            else if (index_y == size_y - 1 && walking_sw) begin
              
            end
          end


          
        end

        ERROR: begin
          
        end

        FOUND: begin
          if (write_out_index < sp) begin
            o_data <= path_stack[write_out_index];
            o_valid <= 1;
            if (write_out_index == sp - 1) begin
              o_last <= 1;
            end
            write_out_index <= write_out_index + 1;
          end
          else begin
            o_valid <= 0;
            o_last <= 0;
            state <= READING;
          end


        end

        default: begin
          state <= READING;
        end
      endcase
    end
  end

  assign o_data = r_data; // Just a dummy assignement. Replace with your code.
  assign o_valid = r_valid; // Just a dummy assignement. Replace with your code.
  assign o_last = r_last; // Just a dummy assignement. Replace with your code.

endmodule
