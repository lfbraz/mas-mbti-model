/**
* Name: buyer_seller
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model buyer_seller
import "mbti.gaml"

global {
	
	int nb_buyers <- 30;
	int nb_items_to_buy <- 100;

	int view_distance <- 20;
	int cycle <- 0;
	int max_cycles <- 1000;

	init {
		//create Seller {
		//	write "Seller with prob";
		//	do set_my_personality(["I", "S", "T", "J"], true); // Using probability
		//	do show_my_personality();
		//}
		
		create Seller {
			write "Seller without prob";
			do set_my_personality(["I", "S", "T", "J"], false); // Not using probability
			do show_my_personality();
		}
		
		//create Seller {
		//	do set_my_personality(["R", "R", "R", "R"], false); // Not using probability
		//	do show_my_personality();
		//}
		
		create Buyer number: nb_buyers;
	}
	
	reflex stop when:cycle=max_cycles{
		list sellers_demand <- list(Seller collect  (each.current_demand));
		
		do pause;	
	}
	
	reflex count{
		write "cycle: " + cycle; 
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
	int current_demand;
	
	list<point> possible_buyers;
	point target;
	bool got_buyer <- false;
	
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
	
	//if the agent has the belief that there is a possible buyer given location, it adds the desire to interact with the buyer to try to sell items.
	rule belief: new_predicate("location_buyer") new_desire: sell_item strength:10.0;
	
	// plan that has for goal to fulfill the wander desire	
	plan letsWander intention:wander 
	{
		do wander amplitude: 60.0;
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
			
			// TODO: Add J-P 
			
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
				
					// Add number of visits to consider in E-I dichotomy
					invoke add_interactions_with_agent(current_buyer);					
					
					// do persist_seller_action(current_buyer, target);	
					do add_belief(met_buyer);
					invoke add_interacted_target(target);	
					
					// We need to control the cycle a seller visited a buyer to be able to remove after the limit
					pair<point, int> agents_cycle <- point(current_buyer)::cycle;
					invoke add_agents_interacted_within_cycle(agents_cycle);
					
				}
				
				write "remove_belief: location_buyer: " + target;
				do remove_belief(new_predicate("location_buyer", ["location_value"::target]));				
				
				target <- nil;				
				do remove_intention(sell_item, true);
				} 
			}
		}
	}
	
	//plan that has for goal to fulfill the define item target desire. This plan is instantaneous (does not take a complete simulation step to apply).
	plan choose_buyer_target intention: define_buyer_target instantaneous: true{
		write "choose_buyer_target";
		possible_buyers <- get_beliefs(new_predicate("location_buyer")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		
		write "possible_buyers: " + possible_buyers ;
		// Calculate the scores based on MBTI personality
		map<Buyer, float> buyers_score;
		buyers_score <- super.calculate_score(possible_buyers, cycle);
	
		// It is important to check if there is any buyer to consider because T-F can remove all the possible agents
		if (empty(buyers_score)) {
			do remove_intention(sell_item, true);
			do remove_intention(define_buyer_target, true);
			do add_desire(wander);
		} else {
			
			// We get the max score according to the MADM method			
			map<Buyer, float> max_buyer_score <- super.get_max_score(buyers_score);
			
			// Now find the target buyer from its location
			target <- point(max_buyer_score.keys[0]);
			write "target: " + target;
		
		}
		do remove_intention(define_buyer_target, true);
	}
	
	list get_buyers_from_points(list list_of_points){
		list<Buyer> list_of_buyers; 
		loop buyer over: list_of_points{
			add Buyer(buyer) to: list_of_buyers;
		}
		return list_of_buyers;	
	}
	
	

	aspect default {
		image_file buyer_icon <- image_file("../../includes/seller.png");	
		draw buyer_icon size: 4;
		// enable view distance
	    draw circle(view_distance) color:rgb(#yellow,0.5) border: #red;
	}
}

species Buyer skills: [moving] {
	rgb color <- #green;
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

experiment Simple type: gui{
	action _init_ {
		create simulation with: (			
			seed: 200
		);
	}
	
	output {
		display map {
			grid grille_low lines: #gray;
			species Seller aspect:default;
			species Buyer aspect:default;
		}
	}
}