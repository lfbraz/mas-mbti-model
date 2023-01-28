/**
* Name: buyer_seller_tests
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model buyer_seller_tests
import "buyer-seller.gaml"

global {
	
	// Vars received from parameters
	int nb_sellers <- 1;
	int nb_buyers <- 1;
	int nb_items_to_buy;
	int nb_items_to_sell;
	list<string> teams_mbti;
	string teams_mbti_string <- 'R,R,R,R';
	int total_demand <- 100;
	string market_type <- "Balanced";
	
	// Global environment vars
	int cycle <- 0;	
	int view_distance;
	int max_cycles <- 1000;
	string scenario <- 'LOW';	
	
	// Staging vars
	int total_sellers_demand;
	int total_buyers_demand;
	
	init {
		write "new simulation created: " + name;
		write "teams_mbti_string: " + teams_mbti_string;
		write "nb_sellers: " + nb_sellers;
		
		// Set teams MBTI profile
		teams_mbti <- list(teams_mbti_string split_with ",");
		
		// Calculate Market Demand
		do calculate_market_demand(market_type, total_demand);
		
		// density cluster
		create Buyer number: 1 {
			set location <- myself.location + {-45, -10};
		}
		
		create Buyer number: 1 {
			set location <- myself.location + {-40, -10};
		}
		
		create Buyer number: 1 {
			set location <- myself.location + {-35, -10};
		}
		
		create Buyer number: 1 {
			set location <- myself.location + {-30, -8};
		}
	
		create Buyer number: 1 {
			set location <- myself.location + {-45, -5};
		}
		
		create Buyer number: 1 {
			set location <- myself.location + {-40, -5};
		}		
		
		create Buyer number: 1 {
			set location <- myself.location + {-35, -5};
		}
		
		// closer buyer
		create Buyer number: 1 {
			set location <- {40, 30};
		}	
		
		// isolated buyer
		create Buyer number: 1 {
			set location <- {25.0, 55.0};
		}		
		
		// less density cluster
		create Buyer number: 1 {
			set location <- {5.0, 25.0};
		}
		
		create Buyer number: 1 {
			set location <- {10.0, 28.0};
		}
		
		create Buyer number: 1 {
			set location <- {5.0, 30.0};
		}		
		// end of less density cluster
		
	}
	
}

experiment buyer_seller_test type: gui benchmark: false  {
	float minimum_cycle_duration <- 0.00;
	
	float seed <- 1985.0;
	
	// Set simulation default values
	float seed_value <- 1985.0 with_precision 1;
	string market_type <- "Balanced";
	string scenario <- 'LOW';
	int max_cycles <- 1000;
	int view_distance <- 20;
	int nb_sellers <- 1;

	//reflex t when: every(10#cycle) {
	//	do compact_memory;
	//}
	
	/** Insert here the definition of the input and output of the model */
	output {
		display map {
			grid grille_low lines: #darkgreen;
			species Seller aspect:default;
			species Buyer aspect:default;
		}
	}
	
	user_command "Seller E" {create Seller number: nb_sellers {
							 do set_my_personality(["E", "Z", "Z", "Z"], false);
							 set location <- {40, 40};
							 set view_distance <- 30.0;
							 }}
							 
	user_command "Seller I" {create Seller number: nb_sellers {
							 do set_my_personality(["I", "Z", "Z", "Z"], false);
							 set location <- {40, 40};
							 set view_distance <- 30.0;
							 }}
	
	user_command "Seller S" {create Seller number: nb_sellers {
							 do set_my_personality(["Z", "S", "Z", "Z"], false);
							 set location <- {40, 40};
							 set view_distance <- 30.0;
							 }}
	
	user_command "Seller N" {create Seller number: nb_sellers {
							 do set_my_personality(["Z", "N", "Z", "Z"], false);
							 set location <- {40, 40};
							 set view_distance <- 30.0;
							 }}
							 
	user_command "Seller T" {create Seller number: nb_sellers {
							 do set_my_personality(["Z", "Z", "T", "Z"], false);
							 set location <- {40, 40};
							 set view_distance <- 30.0;
							 }
							 
							 create Seller number: nb_sellers {
							 do set_my_personality(["I", "Z", "Z", "Z"], false);
							 set location <- {35, 25};
							 set view_distance <- 30.0;
							 }}
	
	user_command "Seller F" {create Seller number: nb_sellers {
						 do set_my_personality(["Z", "Z", "F", "Z"], false);
						 set location <- {40, 40};
						 set view_distance <- 30.0;
						 }
						 create Seller number: nb_sellers {
							 do set_my_personality(["I", "Z", "Z", "Z"], false);
							 set location <- {35, 25};
							 set view_distance <- 30.0;
							 }}
	
	user_command "Seller J" {create Seller number: nb_sellers {
						 do set_my_personality(["Z", "Z", "F", "J"], false);
						 set location <- {40, 40};
						 set view_distance <- 25.0;				 
						 }
						 create Seller number: nb_sellers {
							 do set_my_personality(["E", "Z", "Z", "Z"], false);
							 set location <- {35, 30};
							 set view_distance <- 25.0;
							 }
						 }
	
	user_command "Seller P" {create Seller number: nb_sellers{
						 do set_my_personality(["Z", "Z", "F", "P"], false);
						 set location <- {40, 40};
						 set color <- #red;
						 set view_distance <- 25.0;
						 }
						 create Seller number: nb_sellers {
							 do set_my_personality(["E", "Z", "Z", "Z"], false);
							 set location <- {35, 30};
							 set view_distance <- 25.0;
						 }
					}
	
							 
	user_command "Seller IN" {create Seller number: nb_sellers {
						 do set_my_personality(["I", "N", "Z", "Z"], false);
						 set location <- {40, 40};
						 set view_distance <- 30.0;
						 }}
						 
	user_command "General Tests" {create Seller number: 2 {
		// The performance must be 22
						 do set_my_personality(["E", "E", "E", "E"], false);
						 set view_distance <- 20.0;
						 set location <- {40, 40};
						 }}
}

	
