module top
   (
      input CLOCK_50,         // Horloge 50MHz
      output GPIO_WS2812B     // à relier à l'entrée IN de l'anneau
   );
   
   localparam NB_LEDS = 12;      // Anneau avec 12 LED adressables
   localparam ON      = 8'h20,   // luminosité maxi=255, mais /!\ la consommation si toutes les Led sont allumées 
              OFF     = 8'h00;
   
    wire [7:0]    red;
    wire [7:0]    green;
    wire [7:0]    blue;
    wire [7:0]    address;       // numéro de la Led entre 0 et NB_LEDS-1
    wire          load;          // chargement du registre si load=1
    wire          latch_n;       // déverrouillage et transfert du registre sur front descendant

    reg [3:0] state = 0;      // état courant
  
    wire [23:0] rgb;
    reg [25:0] delay = 0;
    
    assign red    = rgb[23-: 8]; // bits 23 à 16
    assign green  = rgb[15-: 8]; // bits 15 à 8
    assign blue   = rgb[7-: 8];  // bits 7 à 0
   
    // instanciation contrôleur WS2812B
    ws2812b_controller #(.NB_LEDS(NB_LEDS)) ws2812b_controller_inst 
      (
        .clk(CLOCK_50),
        //.reset(1'b0),
        .data_ws2812b(GPIO_WS2812B),
        .address(address),
        .red(red),
        .green(green),
        .blue(blue),
        .load(load),
        .latch_n(latch_n)
      );

    integer i;  
    
    reg [23:0] led[0:NB_LEDS-1]; // état des LED
  
    initial begin // synthétisable avec Quartus Pro
    //            Red, Green, Blue
      led[0]   <= { ON , OFF, OFF}; // Led 0, Red
      led[1]   <= { OFF, ON , OFF}; // Led 1, Green
      led[2]   <= { OFF, OFF, ON }; // Led 2, Blue
      led[3]   <= { ON , ON , OFF}; // Led 3, Yellow
      led[4]   <= { ON , OFF, ON }; // Led 4, Purple
      led[5]   <= { OFF, ON , ON }; // Led 5, Cyan
      led[6]   <= { ON , ON , ON }; // Led 6, White
      led[7]   <= { OFF, ON , ON }; // Led 7, Cyan
      led[8]   <= { ON , OFF, ON }; // Led 8, Purple
      led[9]   <= { ON , ON , OFF}; // Led 9, Yellow
      led[10]  <= { OFF, OFF, ON }; // Led 10, Blue
      led[11]  <= { OFF, ON , OFF}; // Led 11, Green 
    end
     
   // assignation des sorties
   assign load = state < NB_LEDS;
   assign address = load ? state : 0;
   assign rgb = load ? led[state] : 0;
   assign latch_n = ~(state == NB_LEDS);

    
    // machine à états finis
    always @(posedge CLOCK_50) begin

      if (state < NB_LEDS) begin // chargement des couleurs pour chaque LED dans le registre
         state <= state + 1;
      end else begin
         case (state)
            NB_LEDS: begin // déverrouillage et transferts des données
               state <= state + 1;              
            end
            
            NB_LEDS+1: begin // rotation des Led
               if (delay[22]==1) begin // si fin temporisation
                  led[0] <= led[NB_LEDS - 1];
                  for (i=1; i<=NB_LEDS-1; i=i+1) begin
                     led[i] <= led[i-1];
                  end
                  
                  state <= 0; // retour à l'état initial
                  delay <= 0;
               end else begin
                  delay <= delay + 1;
               end
            end
         
            default: begin
               //
            end
         
         endcase
               
      end 
    
    end
    
    
endmodule
