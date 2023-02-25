/**
* Name: buyersellerlow
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model buyersellerlow
import "../buyer_seller.gaml"


experiment buyer_seller_low_01 type: gui keep_seed: true autorun: false{
	// Parameters
	parameter "Number of Sellers" category:"Agents" var: nb_sellers <- 3 among: [1,3,8,10,15,20];
	parameter "Number of Buyers" category:"Agents" var: nb_buyers <- 10 among: [10,50,100,200,400,500, 1280, 6400, 24320];
	parameter "Teams MBTI" var: teams_mbti_string <- "E,R,R,R";
	parameter "Seed" var: seed <- 1985.0 with_precision 1;
	
	// Set simulation default values
	int nb_sellers <- 78;
	int nb_buyers <- 313;
	int total_demand <- 4688; // LOW
	string market_type <- "Balanced";
	string scenario <- 'LOW';
	int max_cycles <- 250;
	int view_distance <- 20;
	
	//float seed_value <- 1985.0 with_precision 1;
    //float seed <- seed_value; // force the value of the seed.
	
	action _init_ {		
		create simulation with: (			
			//seed: seed_value, // Here we don'to set the seed value because we can inherit from the headless experiment
			nb_sellers:nb_sellers,
			nb_buyers:nb_buyers,
			total_demand: total_demand,
			market_type:market_type,
			scenario: scenario,
			max_cycles: max_cycles,
			view_distance: view_distance,
			teams_mbti_string: "E,R,R,R");
			
		create Seller number: nb_sellers {
			do set_my_personality(teams_mbti, false); // Not using probability
			//do show_my_personality();
			set view_distance <- 20;
		}
		
		create Buyer number: nb_buyers;	
	}
	
	output {
		display map {
			grid grille_low lines: #gray;
			species Seller aspect:default;
			species Buyer aspect:default;
		}
	}
}