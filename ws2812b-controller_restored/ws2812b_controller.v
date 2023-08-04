/*
ws2812b controller, voir aussi https://github.com/michaelpearson/ws2812b-verilog
Aout 2023
*/

module ws2812b_controller #(parameter NB_LEDS = 12)
   (
      input clk,				// borloge 50 MHz
      //input reset,       // reset du ruban
      input [7:0] red,
      input [7:0] green,
      input [7:0] blue,
      input [7:0] address, // numéro de la Led entre 0 et NB_LEDS-1
      input load,          // chargement du registre interne (colors)
      input latch_n,       // déverrouille les données et débute la transmission sur front descendant
      
      output data_ws2812b
   );
   
   reg [24 * NB_LEDS - 1 : 0] colors = 0;
   reg latch_n_previous = 1;
   
   localparam  T_HIGH   = 20, // 20 périodes à 50 Mhz = 20 x 20ns = 0,4 us
               T_LOW    = 40, // 40 périodes à 50 Mhz = 40 x 20ns = 0,8 us
               //T_RESET   = 3250,
               T        = T_HIGH + T_LOW;
               
   reg [11:0] t_counter = 0;           // compteur pour le temps
   reg [13:0] rgb_data_index = 0;      // indice de position entre 0 et 23 
   reg transfer_state_reg = 0;
   
   wire load_state;
   wire transfer_state;
   assign load_state = (load==1) & (address < NB_LEDS);
   assign transfer_state = (transfer_state_reg==1) & (~load_state);
   
   
   always@(posedge clk) begin
      if (load_state) begin  // chargement du registre
         colors[(24 * (NB_LEDS - address) - 1)-:24] = {green, red, blue};
      end
   end
   

   always@(posedge clk) begin
      if (transfer_state) begin  // transmission des données

         t_counter <= t_counter - 12'b1;
         
         if (t_counter==0) begin
            t_counter <= T;
            rgb_data_index <= rgb_data_index - 1;
            
            if (rgb_data_index==0) begin
               t_counter <= T;
               rgb_data_index <= 24 * NB_LEDS - 1;
               transfer_state_reg <= 0;
            end         
         end         
      end // if transfer_state   
      
      else if (!latch_n && latch_n != latch_n_previous) begin // si front descendant de latch_n
         rgb_data_index <= 24 * NB_LEDS - 1;
         t_counter <= T;
         transfer_state_reg <= 1;
      end
      
      latch_n_previous <= latch_n;     
   end

   // signal de sortie  
   assign data_ws2812b = (transfer_state==1) & (colors[rgb_data_index] ? t_counter > (T - T_LOW) : t_counter > (T - T_HIGH));
   
   
endmodule
