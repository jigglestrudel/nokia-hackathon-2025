`timescale 1ns / 1ps
module task_5
#(
  parameter int TASK_INPUT_WIDTH = 8,
  parameter int TASK_OUTPUT_WIDTH = 16,
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
  // States
  reg [7:0] state;
  localparam IDLE =           8'h00;   // 0x00
  localparam SELECT_ITEM =    8'h01;   // 0x01
  localparam INSERT_MONEY =   8'h03;   // 0x03
  localparam VERIFY_FOUNDS =  8'h04;   // 0x04
  localparam DISPENSE_ITEM =  8'h05;   // 0x05
  localparam RETURN_CHANGE =  8'h06;   // 0x06

  // State transitions macros
  localparam logic [7:0] ACT_PUSH_BUTTON   = 8'hAA;
  localparam logic [7:0] ACT_INSERT_MONEY  = 8'hBB;
  localparam logic [7:0] ACT_CANCEL        = 8'hCC;

  // Items macros
  typedef struct packed {
      logic [7:0] id;
      logic [7:0] price;
  } item_t;

  localparam item_t ITEM_CHIPS      = '{id:8'hA1, price:8'd15};
  localparam item_t ITEM_CHOCOLATE  = '{id:8'hB2, price:8'd20};
  localparam item_t ITEM_GUM        = '{id:8'hC3, price:8'd2};
  localparam item_t ITEM_SODA       = '{id:8'hD4, price:8'd75};
  localparam item_t ITEM_COOKIES    = '{id:8'hE5, price:8'd18};

  // Helper function to get item by ID
  function automatic item_t get_item_by_id(logic [7:0] id);
      case (id)
          8'hA1: return ITEM_CHIPS;
          8'hB2: return ITEM_CHOCOLATE;
          8'hC3: return ITEM_GUM;
          8'hD4: return ITEM_SODA;
          8'hE5: return ITEM_COOKIES;
          default: return '{id:8'h00, price:8'd0};
      endcase
  endfunction

item_t current_item;
logic [7:0] money_sum;
logic [15:0] data_reg;
logic valid_reg, last_reg;

always_ff @(posedge i_clk or posedge i_rst) begin
  if(i_rst) begin
    state      <= IDLE;
    money_sum  <= 0;
    current_item <= '{id:8'h00, price:8'd0};
    data_reg   <= 16'h0000;
    valid_reg  <= 1'b0;
    last_reg   <= 1'b0;
  end
  else begin
    //valid_reg <= 1'b0;
    //last_reg  <= 1'b0;

    if (i_valid || i_first) begin
      case (state)
        IDLE: begin
          if (i_data == ACT_PUSH_BUTTON) begin
            state <= SELECT_ITEM;
          end
          else if (i_data == ACT_INSERT_MONEY) begin
            state <= INSERT_MONEY;
          end
          data_reg  <= {IDLE, 8'h00};
          valid_reg <= 1'b1;
        end

        SELECT_ITEM: begin
          current_item <= get_item_by_id(i_data);
          state <= VERIFY_FOUNDS;
          data_reg <= {SELECT_ITEM, 8'h00};
          valid_reg <= 1'b1;
        end

        INSERT_MONEY: begin
          money_sum <= money_sum + i_data;
          state <= VERIFY_FOUNDS;
          data_reg <= {INSERT_MONEY, 8'h00};
          valid_reg <= 1'b1;
        end

        VERIFY_FOUNDS: begin
          if (i_data == ACT_PUSH_BUTTON) begin
            state <= SELECT_ITEM;
          end
          else if (i_data == ACT_CANCEL) begin
            if (money_sum == 0)
              state <= IDLE;
            else
              state <= RETURN_CHANGE;
          end
          else if (money_sum >= current_item.price) begin
            state <= DISPENSE_ITEM;
          end
          else begin
            state <= INSERT_MONEY;
          end
          data_reg <= {VERIFY_FOUNDS, 8'h00};
          valid_reg <= 1'b1;
        end

        DISPENSE_ITEM: begin
          data_reg <= {DISPENSE_ITEM, current_item.id};
          valid_reg <= 1'b1;
          if (money_sum == current_item.price) begin
            state <= IDLE;
            //last_reg <= 1'b1;
            //valid_reg <= 1'b0;
            money_sum <= 0;
          end else begin
            state <= RETURN_CHANGE;
          end
        end

        RETURN_CHANGE: begin
          if (money_sum >= current_item.price) begin 
            data_reg <= {RETURN_CHANGE, money_sum - current_item.price};
          end
          else begin
            data_reg <= {RETURN_CHANGE, money_sum};
          end

          valid_reg <= 1'b1;
          //last_reg <= 1'b1;
          state <= IDLE;
          money_sum <= 0;
        end
      endcase

      if(i_last) begin
        last_reg <= 1'b1;
      end
    end
    if(last_reg) begin
      valid_reg <= 1'b0;
      last_reg <= 1'b0;
    end
  end
end

assign o_data  = data_reg;
assign o_valid = valid_reg;
assign o_last  = last_reg;

endmodule