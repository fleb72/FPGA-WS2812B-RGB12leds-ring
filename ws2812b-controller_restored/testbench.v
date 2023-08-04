`timescale 10ns/100ps
// unité de temps = 10ns, résolution = 100ps

module testbench;

    reg clock = 1'b1;
	 //reg reset_sig = 1'b0;
	 reg [7:0] red_sig;
	 reg [7:0] green_sig;
	 reg [7:0] blue_sig;
	 reg [7:0] address_sig; // numéro de la Led entre 0 et NB_LEDS-1
	 reg load_sig;				// chargement du registre
	 reg latch_n_sig;			// déverrouille les données sur état bas

    wire data_ws2812b_sig;

    
    localparam period = 2;  //periode = 2 unités de temps, soit 2 x 10ns = 20ns


    always begin
        #(period/2) clock = ~clock; // génération signal d'horloge
    end
	 
	 ws2812b_controller #(.NB_LEDS(2)) ws2812b_controller_inst
    (
		.clk(clock),
		//.reset(reset_sig),
		.data_ws2812b(data_ws2812b_sig),
		.address(address_sig),
		.red(red_sig),
		.green(green_sig),
		.blue(blue_sig),
		.load(load_sig),
		.latch_n(latch_n_sig)
    );
	 
	 
	 initial begin
		
		//reset_sig <= 0;		
		load_sig <= 0;
		latch_n_sig <= 1;

		#period;
		load_sig <= 1;			// chargement du registre
		
		address_sig <= 0;		// 1ère Led
		red_sig <= 8'h33;
		green_sig <= 8'h44;
		blue_sig <= 8'h55;
		
		#period;
		
		address_sig <= 1;		// 2ème Led
		red_sig <= 8'h66;
		green_sig <= 8'h77;
		blue_sig <= 8'h88;
		
		#period;
		
		load_sig <= 0;
		
		#period latch_n_sig <= 0;	// déverrouillage pour transfert des données du registre
		#period latch_n_sig <= 1;
			 
	 end
	 
	 
endmodule
