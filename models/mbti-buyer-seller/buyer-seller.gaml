/**
* Name: buyer_seller
* The Buyer-Seller approach using a model inspired on MBTI personality type theory 
* Author: lubraz
* Tags: 
*/


model buyer_seller
import "mbti.gaml"

global {
	
	// Vars received from parameters
	int nb_sellers;
	int nb_buyers;
	int nb_items_to_buy;
	int nb_items_to_sell;
	list<string> teams_mbti;
	string teams_mbti_string;
	int total_demand;
	string market_type;
	
	// Global environment vars
	int cycle <- 0;	
	int view_distance;
	int max_cycles;
	string scenario;	
	
	// Staging vars
	int total_sellers_demand;
	int total_buyers_demand;
	
	init {
		write "total_demand: " + total_demand;
		write "seed: " + seed;
		// Set teams MBTI profile
		teams_mbti <- list(teams_mbti_string split_with ",");
		
		// Calculate Market Demand
		do calculate_market_demand(market_type, total_demand);
	}
	
	action calculate_market_demand(string market_type, int total_demand){
		
		if (market_type="Balanced"){
			total_sellers_demand <- (total_demand/2);
			total_buyers_demand <- (total_demand/2);			
		}
		
		if (market_type="Supply>Demand"){
			total_sellers_demand <- ((2/3) * total_demand);
			total_buyers_demand <- (total_demand-total_sellers_demand);			
		}
		
		if (market_type="Demand>Supply"){
			total_buyers_demand <- ((2/3) * total_demand);
			total_sellers_demand  <- (total_demand-total_buyers_demand);			
		}
			
		// Calculate the items to sell and buy according to the market
		nb_items_to_sell <- round(total_sellers_demand/nb_sellers);
		nb_items_to_buy <- round(total_buyers_demand/nb_buyers);
	}
	
	reflex stop when:cycle=max_cycles{
		list sellers_demand <- list(Seller collect  (each.current_demand));

		write "PERFORMANCE: " + (total_sellers_demand - sum(sellers_demand))
			  + " SCENARIO: " + scenario 
			  + " MARKET_TYPE:" + market_type
			  + " TEAMS MBTI: " + teams_mbti
			  + " SEED: " + seed;
		
		do pause;	
	}
	
	reflex count{
		cycle <- cycle + 1;
	}
}

species Seller parent: Person control: simple_bdi{

	// Define agent behavior
	predicate wander <- new_predicate("wander");
	predicate define_item_target <- new_predicate("define_item_target");
	predicate define_buyer_target <- new_predicate("define_buyer_target");
	predicate sell_item <- new_predicate("sell_item");
	predicate say_something <- new_predicate("say_something");
	predicate met_buyer <- new_predicate("met_buyer");
	
	// How many items the Seller can sell
	int current_demand <- copy(nb_items_to_sell);
	
	list<point> possible_buyers;
	point target;
	bool got_buyer <- false;	
	
	bool default_aspect_type <- true;
	
	init{
		// Begin to wander
		do add_desire(wander);
	}
	
	//if the agent perceive a buyer in its neighborhood, it adds a belief concerning its location and remove its wandering intention
	perceive target:Buyer in: view_distance {
		// Seller only focus on buyer if it has demand
		if(self.current_demand > 0){
			focus id:"location_buyer" var:location;
			ask myself {do remove_intention(wander, false);	}	
		}		
	}
	
	perceive target:Seller in: view_distance{
		// We must validate that only our teammates would be considered (also remove the seller itself)
		if(myself.name != self.name){
			focus id:"location_seller" var:location;
			list<point> colleagues_in_my_view_points <- get_beliefs(new_predicate("location_seller")) collect (point(get_predicate(mental_state (each)).values["location_value"]));

			// We must populate the MBTI global var colleagues_in_my_view with the perceived Sellers 
			colleagues_in_my_view <- get_sellers_from_points(colleagues_in_my_view_points); // <<< MBTI >>>>
			do remove_belief(new_predicate("location_seller"));		
		}
	}
	
	//if the agent has the belief that there is a possible buyer given location, it adds the desire to interact with the buyer to try to sell items.
	rule belief: new_predicate("location_buyer") new_desire: sell_item strength:10.0;
	
	// plan that has for goal to fulfill the wander desire	
	plan letsWander intention:wander 
	{
		do wander amplitude: 60.0;
	}
	
	list get_buyers_from_points(list list_of_points){
		list<Buyer> list_of_buyers; 
		loop buyer over: list_of_points{
			add Buyer(buyer) to: list_of_buyers;
		}
		
		return list_of_buyers;	
	}
	
	list get_sellers_from_points(list list_of_points){
		list<Seller> list_of_sellers; 
		loop seller over: list_of_points{
			add Seller(seller) to: list_of_sellers;
		}
		return list_of_sellers;	
	}
	
	// plan that has for goal to fulfill the "sell_item" desire
	plan sellItem intention:sell_item{
		// if the agent does not have chosen a target location, it adds the sub-intention to define a target and puts its current intention on hold
		// the agent will do the same if it has the perceiveing personality, because it has to reconsider it current decision each cycle 
		if (target = nil) {
			do add_subintention(get_current_intention(), define_buyer_target, true);
			do current_intention_on_hold(); 
		} else {
			
			if (Buyer(target).current_demand = 0){
				do remove_belief(new_predicate("location_buyer", ["location_value"::target]));				
				
				target <- nil;				
				do remove_intention(sell_item, true);
			} else {
				
			do goto target: target;
			
			// The J-P dichotomy is an indepent function and must be checked here
			// to calculate if the Seller needs to change the plan 
			point new_target;
			list<Buyer> buyers_in_my_view <- get_buyers_from_points(possible_buyers);
			new_target <- super.get_judging_perceiving(buyers_in_my_view, target, cycle);
			
			if (target != new_target ) {	
				// write "HAS CHANGED THE TARGET";
				// If the target has changed seller must move to this new direction
				target <- new_target;			
				do goto target: target;
			}
			
			//if the agent reach its location, it updates it takes the item, updates its belief base, and remove its intention to get item
			if (target = location)  {
				got_buyer <- true;
				
				Buyer current_buyer <- Buyer first_with (target = each.location);
				if current_buyer != nil and current_buyer.current_demand > 0{
					
					// Update demand of the current buyer
					ask current_buyer {
						visited <- true; 
						current_demand <- current_demand-1;
					}
					
					// Update demand of the current seller
					current_demand <- current_demand-1;
					
					// If there is no sellers' demand we kill the seller
					if current_demand = 0 {
						do die;
					}
					
					do add_belief(met_buyer);
					
					//                  <<<<< BEGIN-MBTI >>>>
					// We increment the number of interactions with the current_buyer to consider in E-I dichotomy
					invoke increment_interactions_with_agent(current_buyer);					
					
					// We add the target (point) in the list of interacted targets				
					invoke add_interacted_target(target);	
					
					// We need to control the cycle a Seller visited a Buyer to be able to remove it after the limit
					pair<point, int> agents_cycle <- point(current_buyer)::cycle;
					invoke add_agents_interacted_within_cycle(agents_cycle);
					
				}
				
				do remove_belief(new_predicate("location_buyer", ["location_value"::target]));				
				
				target <- nil;				
				do remove_intention(sell_item, true);
				} 
			}
		}
	}
	
	//plan that has for goal to fulfill the define item target desire. This plan is instantaneous (does not take a complete simulation step to apply).
	plan choose_buyer_target intention: define_buyer_target instantaneous: true{

		possible_buyers <- get_beliefs(new_predicate("location_buyer")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		
		// Remove interacted targets according to the model constraints
		list<point> agents_to_calculate <- super.remove_interacted_target(possible_buyers, cycle); //  <<<<< MBTI >>>>
		list<Buyer> buyers_in_my_view <- get_buyers_from_points(agents_to_calculate);
		
		// Calculate the scores based on MBTI personality
		map<Buyer, float> buyers_score;
		buyers_score <- super.calculate_score(buyers_in_my_view, cycle); //  <<<<< MBTI >>>>
	
		// It is important to check if there is any buyer to consider because T-F can remove all the possible agents
		if (empty(buyers_score)) {
			do remove_intention(sell_item, true);
			do remove_intention(define_buyer_target, true);
			do add_desire(wander);
		} else {
			
			// We get the max score according to the MADM method			
			map<Buyer, float> max_buyer_score <- super.get_max_score(buyers_score); 		//  <<<<< MBTI >>>>
			
			// Now find the target buyer from its location
			target <- point(max_buyer_score.keys[0]);
		
		}
		do remove_intention(define_buyer_target, true);
	}
	
	aspect default {
		 if(default_aspect_type){draw circle(2) color: #purple;} 
	  	 else {draw square(2) color: #purple;}
		// enable view distance
	    draw circle(view_distance) color:rgb(#yellow,0.5) border: #red;
	    
	    draw (string(self.my_personality)) color:#black size:4 at:{location.x-3,location.y+3};
	}
}

species Buyer skills: [moving] {
	rgb color <- #blue;
	bool visited <- false;
	int current_demand;
	
	init{
		current_demand <- copy(nb_items_to_buy);
	}
	
	aspect default {
		draw triangle(3) color: current_demand=0? #red : color at:{location.x,location.y};		
	}
}

grid grille_low width: 5 height: 5 {
	rgb color <- #white;
}

experiment buyer_seller_default type: gui keep_seed: true{
	// Parameters
	parameter "Number of Sellers" category:"Agents" var: nb_sellers <- 3 among: [1,3,8,10,15,20];
	parameter "Number of Buyers" category:"Agents" var: nb_buyers <- 10 among: [10,50,100,200,400,500, 1280, 6400, 24320];
	parameter "Teams MBTI" var: teams_mbti_string <- "E,R,R,R";
	
	// Set simulation default values
	//float seed_value <- 1985.0 with_precision 1;
	int nb_sellers <- 2;
	int nb_buyers <- 100;
	int total_demand <- 1000; // LOW
	string market_type <- "Balanced";
	string scenario <- 'LOW';
	int max_cycles <- 1000;
	int view_distance <- 20;
	
	float seed_value <- 1985.0;
    float seed <- seed_value; // force the value of the seed.
	
	action _init_ {		
		create simulation with: (			
			seed: seed_value,
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
			do show_my_personality();
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