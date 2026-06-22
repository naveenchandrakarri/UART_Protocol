`timescale 1ns / 1ps

module uart(
  input clk,
  input rst,
  input [2:0] baud_sel,
  input parity_en,
  input parity_type,
  input [3:0] length,
  input newd,
  input [7:0] din,
  output  done_rx,
  output  [7:0] rx_data,
  output frame_err,
  output parity_err,
  output  done_tx
);
  
  wire tx ; 
  wire rx ;
  wire tx_tick;
  wire rx_tick;

  clk_gen gen(clk, rst, baud_sel, tx_tick, rx_tick);
  tx t (clk, rst , tx_tick, newd, length, parity_en, parity_type, din, done_tx, tx);
  rx r (clk, rst, rx_tick, length, rx, parity_en, parity_type, done_rx, frame_err, parity_err, rx_data);

  assign rx = tx;

endmodule

module tx(
  input clk,
  input rst,
  input tx_tick,
  input newd,
  input [3:0] length,
  input parity_en,
  input parity_type,
  input [7:0] din,
  output reg done_tx,
  output reg tx
);

parameter idle     = 0,    
          transfer = 1,
          stop     = 2,
          parity   = 3,
          start    = 4;

reg [3:0] state ;
reg [7:0] temp;
reg parity_bit ;
int i = 0 ;


always @(*) begin
  // even parity
  if(parity_type == 1) begin
    case(length)
    4'd5 : parity_bit = ^(temp[4:0]);
    4'd6 : parity_bit = ^(temp[5:0]);
    4'd7 : parity_bit = ^(temp[6:0]);
    4'd8 : parity_bit = ^(temp[7:0]);
    default : parity_bit = 1'b0;
    endcase
  end

  // odd parity
  else begin
    case(length)
    4'd5 : parity_bit = ~^(temp[4:0]);
    4'd6 : parity_bit = ~^(temp[5:0]);
    4'd7 : parity_bit = ~^(temp[6:0]);
    4'd8 : parity_bit = ~^(temp[7:0]);
    default : parity_bit = 1'b0;
    endcase
  end
end


always @(posedge clk or posedge rst) begin
  if(rst) begin
    done_tx <= 1'b0;
    tx <= 1'b1;
    i <= 0;
    temp <= 8'b0;
    state <= idle ;
  end

  else begin

    if (tx_tick) begin
    case(state)

  idle : begin
      tx <= 1'b1;
      done_tx <= 1'b0;
      state <= start; 
  end

  start : begin 
    if(newd) begin
        temp <= din;
        i <= 0;
        tx <= 1'b0;
        state <= transfer;
      end

      else begin
        state <= start;
      end
  end

  transfer : begin

  if(i < length) begin
    tx <= temp[i];
    i <= i + 1;
    state <= transfer;
  end

  else begin
    if (parity_en)begin
    i <= 0;
    tx <= parity_bit;
    state <= parity;
  end

  else begin
    i <= 0;
    tx <= 1'b1;
    state <= stop;
  end
  end
  end

  parity : begin
  tx <= 1'b1;
  state <= stop;
  end

  stop : begin
  done_tx <= 1'b1;
  state <= idle;
  end

default : state <= idle;
endcase

end
   
  end
  end
  
endmodule

module rx(
  input clk,
  input rst,
  input rx_tick,
  input [3:0]length,
  input rx,
  input parity_en,
  input parity_type,
  output reg done_rx,
  output reg ack,
  output reg err,
  output reg [7:0]rx_data
);

parameter idle     = 0,
          transfer = 1,
          parity   = 2,
          stop     = 3,
          start    = 4;

reg [2:0] state;
reg [7:0] temp;
reg s;
reg parity_bit;
int i = 0 ;
int sample_cnt = 0;

always@(posedge clk or posedge rst) begin
  if(rst) begin
    done_rx <= 1'b0;
    rx_data <= 8'b0;
    parity_bit <= 0;
    err <= 0;
    i <= 0;
    s <= 0;
    temp <= 8'b0;
    ack <= 0;
    sample_cnt <= 0;
    state <= idle ;
  end

  else begin
    if (rx_tick) begin
    case(state)
    idle : begin
      parity_bit <= 0;
      done_rx <= 0;
      err <= 0;
      i <= 0;
      temp <= 8'b0;
      if(sample_cnt == 15) begin
      sample_cnt <= 0;
      state <= start;
      end
      else begin
      sample_cnt <= sample_cnt + 1;
      state <= idle;
      end
    end

    start: begin
    if(sample_cnt == 7) begin
        if(rx == 0)
            s <= 1 ; 
            else
            s <= 0;
            sample_cnt <= sample_cnt + 1; 
            state <= start;      
    end
    else if(sample_cnt == 15) begin
      sample_cnt <= 0;
      if(s)
      state <= transfer;
      else
      state <= start;
      end
      else begin
      sample_cnt <= sample_cnt + 1;
      state <= start;
      end
end

    transfer : begin
      if ( i < length ) begin
        if(sample_cnt == 7) begin 
          temp[i] <= rx;
          state <= transfer;
          sample_cnt <= sample_cnt + 1;
        end
        else if(sample_cnt == 15) begin
          sample_cnt <= 0;
          i <= i + 1;
          state <= transfer;
        end
        else begin
          sample_cnt <= sample_cnt + 1;
          state <= transfer;
        end
      end

      else begin   
        if(parity_en) begin
          if(sample_cnt == 7) begin
            sample_cnt <= sample_cnt + 1;
            parity_bit <= rx;
            rx_data <= temp;
            state <= transfer;
          end
          else if(sample_cnt == 15) begin
            sample_cnt <= 0;
            state <= parity;
          end
          else begin
            sample_cnt <= sample_cnt + 1;
            state <= transfer;
          end
        end

        else begin
          if(sample_cnt == 7) begin
            sample_cnt <= sample_cnt + 1;
            if(rx != 1'b1) begin 
              ack <= 1'b1;
            end
            else
            ack <= 1'b0;
            rx_data <= temp;
            state <= transfer;
          end
          else if(sample_cnt == 15) begin
            sample_cnt <= 0;
            state <= stop;
          end
          else begin
            sample_cnt <= sample_cnt + 1;
            state <= transfer;
          end
          
        end
      end
    end

   parity : begin

    if(parity_type) begin

      case(length)

        4'd5 : err <= (^(rx_data[4:0]) != parity_bit);
        4'd6 : err <= (^(rx_data[5:0]) != parity_bit);
        4'd7 : err <= (^(rx_data[6:0]) != parity_bit);
        4'd8 : err <= (^(rx_data[7:0]) != parity_bit);

      endcase
    end

    else begin

      case(length)

        4'd5 : err <= (~^(rx_data[4:0]) != parity_bit);
        4'd6 : err <= (~^(rx_data[5:0]) != parity_bit);
        4'd7 : err <= (~^(rx_data[6:0]) != parity_bit);
        4'd8 : err <= (~^(rx_data[7:0]) != parity_bit);

      endcase
    end

    if(sample_cnt == 7) begin
      sample_cnt <= sample_cnt + 1;
            if(rx != 1'b1) begin 
              ack <= 1'b1;
            end
            else
            ack <= 1'b0;
            state <= parity;
          end
          else if(sample_cnt == 15) begin
            sample_cnt <= 0;
            state <= stop;
          end
          else begin
            sample_cnt <= sample_cnt + 1;
            state <= parity;
          end
   end

   stop : begin
    if(sample_cnt == 7) begin
    sample_cnt <= sample_cnt + 1;
    done_rx <= 1;
    state <= stop;
    end
    else if(sample_cnt == 15) begin
    i <= 0;
    state <= idle;
    end
    else begin
        sample_cnt <= sample_cnt +1 ;
        state <= stop;
    end
  end

  default : state <= idle;
  endcase
  end
  end
end

endmodule


module clk_gen#(
    parameter CLK_FREQ = 100_000_000
)(
  input clk,
  input rst,
  input [2:0] baud_sel,
  output reg tx_tick,
  output reg rx_tick
);

reg [16:0] baud_div = 0;
reg [16:0] tx_count;
reg [16:0] rx_count;

always @(*) begin
   case(baud_sel)
   3'b000 : baud_div = CLK_FREQ / 1200   ;
   3'b001 : baud_div = CLK_FREQ / 2400   ;
   3'b010 : baud_div = CLK_FREQ / 4800   ;
   3'b011 : baud_div = CLK_FREQ / 9600   ;
   3'b100 : baud_div = CLK_FREQ / 115200 ;
   3'b101 : baud_div = CLK_FREQ / 921600 ;
   default : baud_div = CLK_FREQ / 115200;
    endcase
end

always @(posedge clk or posedge rst) begin

  if(rst) begin
    tx_count   <= 0;
    tx_tick  <= 0;
  end

  else begin

      if(tx_count == baud_div - 1) begin
        tx_count <= 1'b0;
        tx_tick <= 1'b1;
      end

      else begin
        tx_count <= tx_count + 1;
        tx_tick <= 0;
      end
      
    end
  end

  always @(posedge clk or posedge rst) begin

  if(rst) begin
    rx_count   <= 0;
    rx_tick  <= 0;
  end

  else begin

      if(rx_count >= baud_div-16) begin
        rx_count <= rx_count + 16 - baud_div;
        rx_tick <= 1;
    end
    else begin
        rx_count <= rx_count + 16;
        rx_tick <= 0;
    end
      
    end
  end

endmodule
 

interface uff_if;

  logic clk;
  logic rst;
  logic [2:0] baud_sel;
  logic parity_en;
  logic parity_type;
  logic [3:0] length;
  logic newd;
  logic [7:0] din;
  logic done_rx;
  logic [7:0] rx_data;
  logic frame_err;
  logic parity_err;
  logic done_tx;
            
endinterface
