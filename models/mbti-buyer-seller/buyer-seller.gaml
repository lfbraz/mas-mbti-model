/**
* Name: buyer_seller
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model buyer_seller
import "mbti.gaml"

global {
	
	int nb_buyers <- 50;
	int nb_items_to_buy <- 100;

	int view_distance <- 10;
	int steps <- 0;
	int max_steps <- 1000;
	list<point> all_no_demand_buyers;	

	init {
		//create Seller {
		//	write "Seller with prob";
		//	do set_my_personality(["I", "S", "T", "J"], true); // Using probability
		//	do show_my_personality();
		//}
		
		//create Seller {
		//	write "Seller without prob";
		//	do set_my_personality(["I", "S", "T", "J"], false); // Not using probability
		//	do show_my_personality();
		//}
		
		create Seller {
			do set_my_personality(["R", "R", "R", "R"], false); // Not using probability
			do show_my_personality();
		}
		
		create Buyer number: nb_buyers;
	}
	
	reflex stop when:steps=max_steps{
		list sellers_demand <- list(Seller collect  (each.current_demand));
		
		do pause;	
	}
	
	reflex count{
		steps  <- steps + 1;
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
	
	int number_of_cycles_to_return_visited_buyer <- 75;
	int max_number_of_visits_to_a_visited_buyer <- 3;
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
					pair<point, int> agents_step <- point(current_buyer)::steps;
					write "before-add_agents_interacted_within_cycle: " + agents_step;  
					invoke add_agents_interacted_within_cycle(agents_step);
					
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
		map<Buyer, float> num_visits_to_the_buyer_init <- map<Buyer, float>(get_buyers_from_points(possible_buyers) collect (each:: 0.0));
		
		num_interactions_with_the_agent <- map<Buyer, float>((num_visits_to_the_buyer_init.keys - num_interactions_with_the_agent.keys) collect (each::num_visits_to_the_buyer_init[each]) 
									+ num_interactions_with_the_agent.pairs);
		
		// If a target was already visited we must removed it
		possible_buyers <- remove_visited_target(possible_buyers);
		
		write "possible_buyers-" + possible_buyers;
		
		// Calculate the scores based on MBTI personality
		map<Buyer, float> buyers_score;
		list<agent> buyers_in_my_view;

		buyers_in_my_view <- get_buyers_from_points(possible_buyers);
		
		buyers_score <- super.calculate_score(buyers_in_my_view);		
		
		write "choose_buyer_target-" + buyers_score;
		
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
	
	list remove_visited_target(list list_of_points){
		map<point, int> buyers_within_limit ; 
		list<point> buyers_to_remove;

		// Here we have a parameter to define the min cycles to consider before a seller can return to an already visited buyer
		write "agents_interacted_within_cycle-" + agents_interacted_within_cycle;
		buyers_within_limit <- map<point, int>(agents_interacted_within_cycle.pairs where ((steps - each.value) < number_of_cycles_to_return_visited_buyer));
		buyers_to_remove <- buyers_within_limit.keys;

		// Here we have a parameter to define the max number of visits to consider as a limit to a seller be able to visit again the same buyer
		buyers_within_limit  <- map<point, int>(agents_interacted_within_cycle.pairs where ((each.value) >= max_number_of_visits_to_a_visited_buyer ));
		buyers_to_remove <- (buyers_to_remove union buyers_within_limit.keys);
		
		write "buyers_to_remove-" + buyers_to_remove;

		remove all:buyers_to_remove from: list_of_points;
		
		// We remove all buyers with no demand
		remove all:all_no_demand_buyers from: list_of_points;		
		
		return list_of_points;
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

grid grille_low width: 10 height: 10 {
	rgb color <- #white;
}

experiment Simple type: gui{
	action _init_ {
		create simulation with: (			
			seed: 0
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