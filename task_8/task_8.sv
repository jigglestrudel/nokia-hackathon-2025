`timescale 1ns / 1ps
module task_8 #(
    parameter int TASK_INPUT_WIDTH  = 8,
    parameter int TASK_OUTPUT_WIDTH = 8,
    parameter int INPUT_STREAMS     = 1,
    parameter int OUTPUT_STREAMS    = 1
)(
    input  logic                      i_clk,
    input  logic                      i_rst,
    input  logic                      i_first,
    input  logic                      i_last,
    input  logic [TASK_INPUT_WIDTH-1:0] i_data,
    input  logic                      i_valid,
    output logic [TASK_OUTPUT_WIDTH-1:0] o_data,
    output logic                      o_last,
    output logic                      o_valid
);

  // Parameters
  localparam int SIZE = 64;
  localparam int TOTAL_CELLS = SIZE * SIZE;
  localparam int TOTAL_BYTES = TOTAL_CELLS / 8;

  typedef enum logic [1:0] {
    IDLE,
    LOAD,
    SIMULATE,
    SEND
  } state_t;

  state_t state, next_state;

  // Storage
  logic [7:0] time_units;
  logic [7:0] data_buffer [0:TOTAL_BYTES-1];
  logic [7:0] output_buffer [0:TOTAL_BYTES-1];
  logic [$clog2(TOTAL_BYTES):0] byte_count;
  logic [$clog2(TOTAL_BYTES):0] out_count;

  logic [0:SIZE-1][0:SIZE-1] current;
  logic [0:SIZE-1][0:SIZE-1] next;

  // FSM state transition
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      state <= IDLE;
    end else begin
      state <= next_state;
    end
  end

  // FSM next state logic
  always_comb begin
    next_state = state;
    case (state)
      IDLE: if (i_valid && i_first) next_state = LOAD;
      LOAD: if (byte_count == TOTAL_BYTES) next_state = SIMULATE;
      SIMULATE: if (time_units == 0) next_state = SEND;
      SEND: if (out_count == TOTAL_BYTES) next_state = IDLE;
    endcase
  end

  // Input loader
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      byte_count <= 0;
      time_units <= 0;
    end else if (state == IDLE && i_valid && i_first) begin
      time_units <= i_data;
    end else if (state == LOAD && i_valid) begin
      data_buffer[byte_count] <= i_data;
      byte_count <= byte_count + 1;
    end
  end

  // Bit unpacker
  task unpack_buffer;
    integer i, j, k;
    begin
      for (i = 0; i < TOTAL_BYTES; i++) begin
        for (j = 0; j < 8; j++) begin
          k = i * 8 + j;
          current[k / SIZE][k % SIZE] = data_buffer[i][j];
        end
      end
    end
  endtask

  // Bit packer
  task pack_buffer;
    integer i, j, k;
    reg [7:0] temp;
    begin
      for (i = 0; i < TOTAL_BYTES; i++) begin
        temp = 0;
        for (j = 0; j < 8; j++) begin
          k = i * 8 + j;
          temp[j] = current[k / SIZE][k % SIZE];
        end
        output_buffer[i] = temp;
      end
    end
  endtask

  // Game of Life logic
  function automatic logic get_next_cell(input int x, input int y);
    int dx, dy, nx, ny, alive_neighbors;
    begin
      alive_neighbors = 0;
      for (dx = -1; dx <= 1; dx++) begin
        for (dy = -1; dy <= 1; dy++) begin
          if (!(dx == 0 && dy == 0)) begin
            nx = x + dx;
            ny = y + dy;
            if (nx >= 0 && nx < SIZE && ny >= 0 && ny < SIZE)
              alive_neighbors += current[nx][ny];
          end
        end
      end
      // Apply Game of Life rules
      if (current[x][y] == 1) begin
        if (alive_neighbors < 2 || alive_neighbors > 3)
          return 0;
        else
          return 1;
      end else begin
        if (alive_neighbors == 3)
          return 1;
        else
          return 0;
      end
    end
  endfunction

  // Simulation controller
  integer x, y;
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      time_units <= 0;
    end else if (state == SIMULATE) begin
      for (x = 0; x < SIZE; x++) begin
        for (y = 0; y < SIZE; y++) begin
          next[x][y] = get_next_cell(x, y);
        end
      end
      for (x = 0; x < SIZE; x++) begin
        for (y = 0; y < SIZE; y++) begin
          current[x][y] <= next[x][y];
        end
      end
      time_units <= time_units - 1;
    end else if (state == LOAD && byte_count == TOTAL_BYTES) begin
      unpack_buffer();
    end else if (state == SEND && out_count == 0) begin
      pack_buffer();
    end
  end

  // Output logic
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      o_data <= 0;
      o_valid <= 0;
      o_last <= 0;
      out_count <= 0;
    end else if (state == SEND) begin
      o_data <= output_buffer[out_count];
      o_valid <= 1;
      o_last <= (out_count == TOTAL_BYTES - 1);
      out_count <= out_count + 1;
    end else begin
      o_valid <= 0;
      o_last <= 0;
    end
  end

endmodule
