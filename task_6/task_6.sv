`timescale 1ns / 1ps
module task_6 #(
  parameter int TASK_INPUT_WIDTH = 8,
  parameter int TASK_OUTPUT_WIDTH = 8,
  parameter int INPUT_STREAMS     = 1,
  parameter int OUTPUT_STREAMS    = 1
)(
  input                         i_clk,
  input                         i_rst,

  input                         i_valid,
  input                         i_first,
  input                         i_last,
  input [TASK_INPUT_WIDTH-1:0]  i_data,

  output logic                  o_valid,
  output logic                  o_last,
  output logic [TASK_OUTPUT_WIDTH-1:0] o_data
);

  logic [TASK_OUTPUT_WIDTH-1:0] r_data; // Just a dummy register. Replace with your code.
  logic r_valid; // Just a dummy register. Replace with your code.
  logic r_last; // Just a dummy register. Replace with your code.
  logic [7:0] size_x, size_y;
  logic  maze_map [63:0][63:0];
  logic [7:0] index_x, index_y;

  logic y_is_next;

  logic [7:0] path_stack [2047:0];
  logic [7:0] UP         = 2'h00;
  logic [7:0] DOWN       = 2'h01;
  logic [7:0] LEFT       = 2'h02;
  logic [7:0] RIGHT      = 2'h03;
  logic [10:0] sp;
  logic [10:0] write_out_index;

  reg [2:0] state;
  localparam IDLE       = 3'b000;
  localparam READING    = 3'b001;
  localparam SEARCHING  = 3'b010;
  localparam ERROR      = 3'b011;
  localparam FOUND      = 3'b100;



  always@(posedge i_clk) begin
    // r_data <= i_data; // Just a dummy assignement. Replace with your code.
    // r_valid <= i_valid; // Just a dummy assignement. Replace with your code.
    // r_last <= i_last; // Just a dummy assignement. Replace with your code.

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
              index_x <= size_x - 8;
              y_is_next <= 0;
            end
            else if (i_last) begin
              // no idea what should happen here lmao
              // lets just put the data byte on the last spot or smth idk
              maze_map[size_y - 1][7] <= i_data[7];
              maze_map[size_y - 1][6] <= i_data[6];
              maze_map[size_y - 1][5] <= i_data[5];
              maze_map[size_y - 1][4] <= i_data[4];
              maze_map[size_y - 1][3] <= i_data[3];
              maze_map[size_y - 1][2] <= i_data[2];
              maze_map[size_y - 1][1] <= i_data[1];
              maze_map[size_y - 1][0] <= i_data[0];

              index_x <= size_x-1;
              index_y <= size_y-1;

              

              sp <= 0;

              state <= SEARCHING;
            end
            else begin
              maze_map[index_y][index_x] <= i_data[0];
              maze_map[index_y][index_x+1] <= i_data[1];
              maze_map[index_y][index_x+2] <= i_data[2];
              maze_map[index_y][index_x+3] <= i_data[3];
              maze_map[index_y][index_x+4] <= i_data[4];
              maze_map[index_y][index_x+5] <= i_data[5];
              maze_map[index_y][index_x+6] <= i_data[6];
              maze_map[index_y][index_x+7] <= i_data[7];
              
              index_x <= index_x - 8;
              if (index_x <= 0) begin
                index_x <= size_x - 8;
                index_y <= index_y + 1;
              end
            end
          end
        end
        IDLE: begin
          // sranie w banie
        end
        SEARCHING: begin

          if (index_x == 0 && index_y == 0) begin
            write_out_index <= 0;
            state <= FOUND;
          end
          else begin
            maze_map[index_y][index_x] <= 1;
            if ((index_y > 0) &&!maze_map[index_y-1][index_x]) begin
              path_stack[sp] <= UP;
              sp <= sp + 1;
              index_y <= index_y - 1;
            end
            else if ((index_y < size_y-1) && !maze_map[index_y+1][index_x]) begin
              path_stack[sp] <= DOWN;
              sp <= sp + 1;
              index_y <= index_y + 1;
            end
            else if ((index_x < size_x-1) &&!maze_map[index_y][index_x+1]) begin
              path_stack[sp] <= LEFT;
              sp <= sp + 1;
              index_x <= index_x + 1;
            end
            else if ((index_x > 0) && !maze_map[index_y][index_x-1]) begin
              path_stack[sp] <= RIGHT;
              sp <= sp + 1;
              index_x <= index_x - 1;
            end
            else begin
              if (sp > 0) begin
                case (path_stack[sp-1])
                  UP: begin
                    index_y <= index_y + 1;
                  end 
                  DOWN: begin
                    index_y <= index_y - 1;
                  end 
                  LEFT: begin
                    index_x <= index_x - 1;
                  end 
                  RIGHT: begin
                    index_x <= index_x + 1;
                  end 
                  default: begin
                    
                  end
                endcase
                sp <= sp - 1;
              end
              else begin
                state <= ERROR;
              end
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

  // assign o_data = r_data; // Just a dummy assignement. Replace with your code.
  // assign o_valid = r_valid; // Just a dummy assignement. Replace with your code.
  // assign o_last = r_last; // Just a dummy assignement. Replace with your code.


endmodule