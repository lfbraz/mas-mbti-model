/**
* Name: buyersellerlow
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model buyersellerlow
import "../buyer_seller.gaml"

global {
	string teams_mbti_string;
	int nb_sellers;
	int nb_buyers;
	int total_demand;
	string market_type;
	string scenario;
	int nb_number_of_cycles_to_return_interacted_agent;
	int nb_max_number_of_visits_to_a_interacted_agent;
	int nb_min_distance_to_exclude;

	init {
			// Set teams MBTI profile
			teams_mbti <- list(teams_mbti_string split_with ",");
		
			// Calculate Market Demand
			do calculate_market_demand(market_type, total_demand);
			
			create Seller number: nb_sellers {
					//do set_my_personality(teams_mbti, false); // Not using probability
					do set_my_personality(teams_mbti, true); // Using probability
					set view_distance <- 20;
					do set_global_parameters(nb_number_of_cycles_to_return_interacted_agent, 
											 nb_max_number_of_visits_to_a_interacted_agent, 
											 nb_min_distance_to_exclude
					);
			}
	
			create Buyer number: nb_buyers;	
	}
}

experiment buyer_seller_low_balanced type: gui keep_seed: true autorun: true{
	// Parameters
	parameter "Teams MBTI" var: teams_mbti_string init: "E,R,R,R";
	parameter "Market Type" var: market_type init: "Balanced";
	parameter "Cycles to return to interacted agent" var: nb_number_of_cycles_to_return_interacted_agent init: 75;
	parameter "Max visits to a interacted agent" var: nb_max_number_of_visits_to_a_interacted_agent init: 3;
	parameter "Min Distance to Exclude" var: nb_min_distance_to_exclude init: 10.0;

	parameter "Sellers" var: nb_sellers init: 78;
	parameter "Buyers" var: nb_buyers init: 313;
	parameter "Total Demand" var: total_demand init: 4688; // LOW
	parameter "Scenario" var: scenario init: "LOW";
	parameter "Max Cycle" var: max_cycles init: 250;
	parameter "View Distance" var: view_distance init: 20;
	
	reflex t when: every(100#cycle) {
		do compact_memory;
	}
	
	output {
		display map {
			grid grille_low lines: #gray;
			species Seller aspect:default;
			species Buyer aspect:default;
		}
	}
}

experiment buyer_seller_low_demand_greater_supply type: gui keep_seed: true autorun: true{
	// Parameters
	parameter "Teams MBTI" var: teams_mbti_string init: "E,R,R,R";
	parameter "Market Type" var: market_type init: "Demand>Supply";
	parameter "Cycles to return to interacted agent" var: nb_number_of_cycles_to_return_interacted_agent init: 75;
	parameter "Max visits to a interacted agent" var: nb_max_number_of_visits_to_a_interacted_agent init: 3;
	parameter "Min Distance to Exclude" var: nb_min_distance_to_exclude init: 10.0;

	parameter "Sellers" var: nb_sellers init: 78;
	parameter "Buyers" var: nb_buyers init: 313;
	parameter "Total Demand" var: total_demand init: 4688; // LOW
	parameter "Scenario" var: scenario init: "LOW";
	parameter "Max Cycle" var: max_cycles init: 250;
	parameter "View Distance" var: view_distance init: 20;
	
	reflex t when: every(100#cycle) {
		do compact_memory;
	}
	
	output {
		display map {
			grid grille_low lines: #gray;
			species Seller aspect:default;
			species Buyer aspect:default;
		}
	}
}


experiment buyer_seller_low_supply_greater_demand type: gui keep_seed: true autorun: true{
	// Parameters
	parameter "Teams MBTI" var: teams_mbti_string init: "E,R,R,R";
	parameter "Market Type" var: market_type init: "Demand>Supply";
	parameter "Cycles to return to interacted agent" var: nb_number_of_cycles_to_return_interacted_agent init: 75;
	parameter "Max visits to a interacted agent" var: nb_max_number_of_visits_to_a_interacted_agent init: 3;
	parameter "Min Distance to Exclude" var: nb_min_distance_to_exclude init: 10.0;

	parameter "Sellers" var: nb_sellers init: 78;
	parameter "Buyers" var: nb_buyers init: 313;
	parameter "Total Demand" var: total_demand init: 4688; // LOW
	parameter "Scenario" var: scenario init: "LOW";
	parameter "Max Cycle" var: max_cycles init: 250;
	parameter "View Distance" var: view_distance init: 20;
	
	reflex t when: every(100#cycle) {
		do compact_memory;
	}
	
	output {
		display map {
			grid grille_low lines: #gray;
			species Seller aspect:default;
			species Buyer aspect:default;
		}
	}
}

experiment buyer_seller_low_sobol type: batch keep_seed: true until: (time>max_cycles) {
	parameter "Teams MBTI" var: teams_mbti_string init: "R,R,R,R";
	parameter "Market Type" var: market_type init: "Balanced";
	parameter "Cycles to return to interacted agent" var: nb_number_of_cycles_to_return_interacted_agent min:50 max:100;
	parameter "Max visits to a interacted agent" var: nb_max_number_of_visits_to_a_interacted_agent min:1 max:5;
	parameter "Min Distance to Exclude" var: nb_min_distance_to_exclude min:5 max:15;

	parameter "Sellers" var: nb_sellers init: 78;
	parameter "Buyers" var: nb_buyers init: 313;
	parameter "Total Demand" var: total_demand init: 4688; // LOW
	parameter "Scenario" var: scenario init: "LOW";
	parameter "Max Cycle" var: max_cycles init: 250;
	parameter "View Distance" var: view_distance init: 20.0;
	method sobol outputs:["performance"] sample: 100 report:"sobol.txt" results:"sobol_raw.csv";
	
}
