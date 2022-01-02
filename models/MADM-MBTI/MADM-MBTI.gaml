/**
* Name: MBTI1
* MBTI model 
* Author: Luiz Braz
* Tags: 
*/

model MBTI

global {
	float seedValue <- 1985.0 with_precision 1;
	
	list<string> teams_mbti;
	string teams_mbti_string <- "";
	
	int iteration_number <- 1;

	int nbsellers;
	int nbbuyers;

	string market_type;
	string scenario;
	
	int total_sellers_demand <-0;
	int total_buyers_demand;
	
	int total_items <- 4688;
	int nbitemstobuy;
	int nbitemstosell;
	
	int view_distance;
	
	bool turn_off_time;
	bool turn_off_personality_probability;
	list<point> visited_target;
		
	int steps <- 0;
	int max_steps;

	list<point> all_no_demand_buyers;

	// map<string, string> PARAMS <- ['dbtype'::'sqlite', 'database'::'../../db/mas-mbti-recruitment.db'];
	// map<string, string> PARAMS_SQL <- ['host'::hostname, 'dbtype'::'sqlserver', 'database'::'TESTEDB', 'port'::'1433', 'user'::'gama_user', 'passwd'::'gama#123'];

	// map<string, string> PARAMS <- ['host'::'localhost', 'dbtype'::'Postgres', 'database'::'gama_data', 'port'::'5432', 'user'::'postgres_user', 'passwd'::'gama#123'];

	action calculate_market_items {		
		
		if (market_type="Balanced"){
			total_sellers_demand <- round(total_items/2);
			total_buyers_demand <- round(total_items/2);			
		}
			
		// Calculate the items according to the market
		nbitemstosell <- round(total_sellers_demand/nbsellers);
		nbitemstobuy <- round(total_buyers_demand/nbbuyers);

		write "nbitemstobuy: " + nbitemstobuy;
		write "nbitemstosell: " + nbitemstosell;
	}
	
	init {
		write "total_items: " + total_items;
		do calculate_market_items();
		write "total_sellers_demand: " + total_sellers_demand;
		
		teams_mbti <- list(teams_mbti_string split_with ",");
		write teams_mbti;
		seed <- seedValue;
		write "New simulation created: " + name + " for the Teams' Personality: " + teams_mbti;
		write "Number of Sellers: " + nbsellers + " / Buyers: " + nbbuyers;
		write "View Distance: " + view_distance;
		
		create sellers number: nbsellers;		
		create buyers number: nbbuyers;
	}
	
	reflex stop when:steps=max_steps{
		list sellers_demand <- list(sellers collect  (each.my_current_demand));

		write "PERFORMANCE: " + (total_sellers_demand - sum(sellers_demand))
			  + " SCENARIO: " + scenario 
			  + " MARKET_TYPE:" + market_type
			  + " TEAMS MBTI: " + teams_mbti;
		
		do pause;	
	}
	
	reflex count{
		write "Performing step: " + steps;
		steps  <- steps + 1;
	}
	
	
	 reflex all_no_demand_buyers {
		//list buyers_demand <- list(buyers collect  (each.my_current_demand));
		list sellers_demand <- list(sellers collect  (each.my_current_demand));
		//write "Demanda atual Buyers: " + sum(buyers_demand);
		//write "Demanda atual Sellers: " + sum(sellers_demand);
		write "Performance atual Sellers: " + (total_sellers_demand - sum(sellers_demand)) ;
	}
	
}

species sellers skills: [moving, SQLSKILL] control: simple_bdi{
	
	int count_people_around <- 0 ;
	bool got_buyer <- false;
	float speed <- 2#km/#h;
	
	// How many items the Seller can sell
	int my_current_demand;
	
	// MBTI variables
	string my_personality;
	list my_real_personality;
	list<string> my_current_personality;
	
	string E_I;
	bool is_extroverted;
	
	string S_N;
	bool is_sensing;
	
	string T_F;
	bool is_thinking;

	string J_P;
	bool is_judging;
	
	rgb color;
	
	//to simplify the writting of the agent behavior, we define as variables 4 desires for the agents
	predicate define_item_target <- new_predicate("define_item_target");
	predicate define_buyer_target <- new_predicate("define_buyer_target");
	predicate sell_item <- new_predicate("sell_item");
	predicate say_something <- new_predicate("say_something");
	predicate wander <- new_predicate("wander");
	predicate met_buyer <- new_predicate("met_buyer");
	
	point target;
	point new_target;

	list<point> perceived_buyers;
	
	list<point> sellers_in_my_view;
	
	list<point> possible_buyers;
	
	float min_distance_to_exclude <- 10.0;
	
	float weight_e_i <- 1/3;
	float weight_s_n <- 1/3;
	float weight_t_f <- 1/3;
	
	int cluster_distance <- 30;	
	
	date start_time;
	date end_time;
	
	map<buyers, float> num_visits_to_the_buyer;
	
	string experiment_name;

	list<buyers> buyers_in_my_view_global;
	map<buyers, float> buyers_distance_to_me_global;
	map<buyers, float> buyers_distance_norm_global;
	
	map<point, int> buyers_visited_in_cycle;
	int number_of_cycles_to_return_visited_buyer <- 75;
	int max_number_of_visit_to_a_visited_buyer <- 3;
	
	bool default_aspect_type <- true;
	
	//at the creation of the agent, we add the desire to patrol (wander)
	init
	{	
        // We must copy the global variable because the pointer issue
        list<string> mbti_personality <- copy(teams_mbti);
        
        // write "Init: " + teams_mbti + " : " + nbitemstosell;
        my_current_demand <- copy(nbitemstosell);
        //write "My Current Demand " + self.name + " " + my_current_demand; 
        mbti_personality <- randomize_personality(mbti_personality);        
        // write "My personality: " + mbti_personality;
        
        // write PARAMS_SQL;
        // write "Connection to SQL is " +  testConnection(PARAMS_SQL);
		// set my personality
		my_personality <- string(mbti_personality);
		my_current_personality <- mbti_personality;		
		
		// clean table
		//do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_SCORE_E_I";
		//do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_SCORE_S_N";
		//do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_SCORE_T_F";
		//do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_TARGET";
		
		// do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_SELLER_PRODUCTIVITY WHERE EXPERIMENT_NAME=?" values: [world.name];
		
		//do executeUpdate params: PARAMS updateComm: "TRUNCATE TABLE TB_SELLER_PRODUCTIVITY"; 
		
		//do define_personality(mbti_personality);
		do define_personality_without_prob(mbti_personality);

		// Begin to wander
		do add_desire(wander);
	}
	
	action define_personality(list<string> mbti_personality){
		E_I <- mbti_personality at 0;
		S_N <- mbti_personality at 1;
		T_F <- mbti_personality at 2;
		J_P <- mbti_personality at 3;
		
		// An seller agent has 80% of probabability to keep its original MBTI personality
		is_extroverted<- E_I = 'E' ? flip(0.8) : flip(0.2);
		is_sensing <- S_N =  'S' ? flip(0.8) : flip(0.2);
		is_thinking <- T_F =  'T' ? flip(0.8) : flip(0.2);
		is_judging <- J_P = 'J' ? flip(0.8) : flip(0.2);
		
		my_real_personality <- [];
		add is_extroverted?"E":"I" to: my_real_personality;
		add is_sensing?"S":"N" to: my_real_personality;
		add is_thinking?"T":"F" to: my_real_personality;
		add is_judging?"J":"P" to: my_real_personality;
		
		color <- #purple;		
	}

	action define_personality_without_prob(list<string> mbti_personality){
		E_I <- mbti_personality at 0;
		S_N <- mbti_personality at 1;
		T_F <- mbti_personality at 2;
		J_P <- mbti_personality at 3;
		
		is_extroverted<- E_I = 'E' ? true : false;
		is_sensing <- S_N =  'S' ? true : false;
		is_thinking <- T_F =  'T' ? true : false;
		is_judging <- J_P = 'J' ? true : false;
		
		my_real_personality <- [];
		add is_extroverted?"E":"I" to: my_real_personality;
		add is_sensing?"S":"N" to: my_real_personality;
		add is_thinking?"T":"F" to: my_real_personality;
		add is_judging?"J":"P" to: my_real_personality;
		
		color <- #purple;		
	}
	
	action randomize_personality (list<string> my_mbti_personality) {
		if my_mbti_personality[0] = 'R' {
				my_mbti_personality[0] <- sample(["E", "I"], 1, false)[0];
		}
		
		if my_mbti_personality[1] = 'R' {
				my_mbti_personality[1] <- sample(["S", "N"], 1, false)[0];
		}
		
		if my_mbti_personality[2] = 'R' {
				my_mbti_personality[2] <- sample(["T", "F"], 1, false)[0];
		}
	
		if my_mbti_personality[3] = 'R' {
				my_mbti_personality[3] <- sample(["J", "P"], 1, false)[0];
		}
		return my_mbti_personality;	
	}
	
	// We use the param each cycle to know when to use the define_personality function 
	reflex get_current_personality{
		my_current_personality <- list(self.my_personality);
		if(turn_off_personality_probability) {do define_personality(my_current_personality);}
	}
	
	//if the agent perceive a buyer in its neighborhood, it adds a belief concerning its location and remove its wandering intention
	perceive target:buyers in: view_distance {
		// Seller only focus on buyer if it has demand
		if(self.my_current_demand > 0){
			focus id:"location_buyer" var:location;
			ask myself {do remove_intention(wander, false);	}	
		}		
	}
	
	perceive target:sellers in: view_distance{
		// We must validate that only our teammates would be considered (also remove the seller itself)
		//if(myself.name != self.name){
		//	focus id:"location_seller" var:location;
		//	sellers_in_my_view <- get_beliefs(new_predicate("location_seller")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		//	do remove_belief(new_predicate("location_seller"));		
		//}
	}
	
	list get_biggest_cluster(list buyers_in_my_view){	  	
	  	list<list<buyers>> clusters <- list<list<buyers>>(simple_clustering_by_distance(buyers_in_my_view, cluster_distance));
	  	// Alter the colors to check if everything is OK
	  	//loop cluster over: clusters {
	  	//   write cluster;
	  	//   rgb rnd_color <- rgb(rnd(255),rnd(255),rnd(255));
	  	//   ask cluster as: buyers {color <- rnd_color;}               		
        //}	 
	  	return clusters with_max_of(length(each));	  	 	
	  }
	  
	list get_buyers_from_points(list list_of_points){
		list<buyers> list_of_buyers; 
		loop buyer over: list_of_points{
			add buyers(buyer) to: list_of_buyers;
		}
		return list_of_buyers;	
	}
	
	list get_sellers_from_points(list list_of_points){
		list<sellers> list_of_sellers; 
		loop seller over: list_of_points{
			add sellers(seller) to: list_of_sellers;
		}
		return list_of_sellers;	
	}
	
	list remove_visited_target(list list_of_points){
		map<point, int> buyers_within_limit ; 
		list<point> buyers_to_remove;

		// Here we have a parameter to define the min cycles to consider before a seller can return to a already visited buyer
		buyers_within_limit <- map<point, int>(buyers_visited_in_cycle.pairs where ((steps - each.value) < number_of_cycles_to_return_visited_buyer));
		buyers_to_remove <- buyers_within_limit.keys;

		// Here we have a parameter to define the max number of visits to consider as a limit to a seller be able to visit again the same buyer
		buyers_within_limit  <- map<point, int>(num_visits_to_the_buyer.pairs where ((each.value) >= max_number_of_visit_to_a_visited_buyer));
		buyers_to_remove <- (buyers_to_remove union buyers_within_limit.keys);
		
		remove all:buyers_to_remove from: list_of_points;
		
		// We remove all buyers with no demand
		remove all:all_no_demand_buyers from: list_of_points;		
		
		return list_of_points;
	}
	
	float get_normalized_values(float value, map<buyers, float> buyers_values, string criteria_type){
		if criteria_type="cost"{
			return value>0 ? abs(min(buyers_values) / value) : 1.0;	
		} else {
			return value>0 ? abs(value / max(buyers_values)) : 0.0;
		}
	}
	
	map<buyers, float> get_distances(list<buyers> buyers_in_my_view){
		return map<buyers, float>(buyers_in_my_view collect (each::self distance_to (each)));
	}
	
	map<buyers, float> get_distances_norm(list<buyers> buyers_in_my_view){
		return map<buyers, float>(buyers_in_my_view collect (each::self distance_to (each)));
	}
	
	action get_buyers_in_my_view(list list_of_buyers){
		buyers_in_my_view_global <- get_buyers_from_points(list_of_buyers);
		buyers_in_my_view_global <- reverse (buyers_in_my_view_global sort_by (each distance_to self));
		
		// Get the distance of each buyer to the seller and calculate the inverted norm score
		buyers_distance_to_me_global  <- get_distances(buyers_in_my_view_global); 
		buyers_distance_norm_global <- buyers_distance_to_me_global.pairs as_map (each.key::(get_normalized_values(each.value, buyers_distance_to_me_global, "cost")));
	}
	
	action get_extroversion_introversion_score{
		map<buyers, float> score_e_i;
		
		// When there is a unique agent we can simply consider it as the max score
		if(length(buyers_in_my_view_global)=1){
			score_e_i <-  map<buyers, float>(buyers_in_my_view_global collect (first(each)::1.0));
		}
		else {			
		
			//map<buyers, float> buyers_size;
			map<buyers, float> num_visits_to_the_buyer_norm;
			
			// Get how many people exists in the buyer
			//buyers_size <- get_buyers_size(buyers_in_my_view_global);

			string criteria_type;
			
			// According to the seller personality type the normalization procedure will change (cost or benefit attribute) 
			criteria_type <- self.is_extroverted ? "cost" : "benefit";			 
			num_visits_to_the_buyer_norm <- num_visits_to_the_buyer.pairs as_map (each.key::float(get_normalized_values(each.value, num_visits_to_the_buyer, criteria_type)));
			
			// Calculate SCORE-E-I
			score_e_i <- buyers_distance_norm_global.pairs as_map (each.key::each.value+(num_visits_to_the_buyer_norm[each.key]));
			
			/* 
			// Log to the database
			loop buyer over: score_e_i.pairs {			
				// log into db the calculated score
				do insert (params: PARAMS,
								into: "TB_SCORE_E_I",
								columns: ["INTERACTION", 
										  "SELLER_NAME", 
										  "MBTI_SELLER", 
										  "DISTANCE_TO_BUYER", 
										  "NUMBER_OF_PEOPLE_AT_BUYER", 
										  "BUYER_NAME",
										  "IS_EXTROVERTED",
										  "SCORE_DISTANCE",
				                          "SCORE_QTY_BUYERS",
										  "SCORE"],
								values:  [steps, 
										  self.name, 
										  self.my_personality, 
										  buyers_distance_to_me[buyer.key], 
										  buyers(buyer.key).qty_buyers, 
										  buyers(buyer.key).name,
										  int(self.is_extroverted),
										  buyers_distance_norm[buyer.key],
										  buyers_size_norm[buyer.key],
										  buyer.value
								]);								
								
			}		
			*/
			
			return score_e_i;	
		}
	}	

	action get_sensing_intuition_score{
		map<buyers, float> score_s_n;
		
		// When there is a unique agent we can simply consider it as the max score
		if(length(buyers_in_my_view_global)=1){
			score_s_n <-  map<buyers, float>(buyers_in_my_view_global collect (first(each)::1.0));
		}
		else {
		
			// Calculate the density using simple_clustering_by_distance technique
			list<list<buyers>> clusters <- list<list<buyers>>(simple_clustering_by_distance(buyers_in_my_view_global, 10));
			
			list<map<list<buyers>, int>> clusters_density <-list<map<list<buyers>, int>>(clusters collect (each::length(each)));
			
			// Here we must navigate in three different levels because of the structure of the list of maps of lists		
			// With that we create a map of buyers with the density of its own cluster
			map<buyers, float> buyers_density;
			loop cluster over:clusters_density{
				loop buyers_by_density over: cluster.pairs{
					loop buyer over: buyers_by_density.key {
						add buyer::buyers_by_density.value to:buyers_density;				
					}				
				}
			}
			
			float distance_weight;
			float density_weight;
			float buyers_closest_to_edge_weight;
			
			density_weight <- self.is_sensing ? 0.1 : 0.25;
			buyers_closest_to_edge_weight <- self.is_sensing ? 0.1 : 0.25;
			distance_weight <- 1 - density_weight - buyers_closest_to_edge_weight; 			
			
			// Normalize density as a benefit attribute
			map<buyers, float> buyers_density_norm;
			buyers_density_norm <- buyers_density.pairs as_map (each.key::(max(buyers_density)>1) ? get_normalized_values(each.value, buyers_density, "benefit") : 1.0);
			
			// Calculate closest cluster point to the edge (perception radius)
			list<point> cluster_list;
			buyers buyer_closest_to_edge;
			map<buyers, float> buyers_closest_to_edge;
			
			loop cluster over: clusters{
				cluster_list <- list<point>((cluster collect each));			
				buyer_closest_to_edge <- buyers(geometry(cluster) farthest_point_to(point(self)));
				add buyer_closest_to_edge::(buyer_closest_to_edge distance_to self) to:buyers_closest_to_edge;
			}
			
			// Normalize buyers_closest_to_edge as a benefit attribute
			map<buyers, float> buyers_closest_to_edge_norm;
			buyers_closest_to_edge_norm <- buyers_closest_to_edge.pairs as_map (each.key::get_normalized_values(each.value, buyers_closest_to_edge, "benefit"));
			
			// Calculate SCORE-S-N
			score_s_n <- buyers_distance_norm_global.pairs as_map (each.key::((each.value*distance_weight)
																			 +(buyers_density_norm[each.key]*density_weight)
																			 +(buyers_closest_to_edge_norm[each.key]*buyers_closest_to_edge_weight)
			));

			/*	
			// Log to the database
			loop buyer over: score_s_n.pairs {
				// log into db the calculated score
				do insert (params: PARAMS,
							into: "TB_SCORE_S_N",
							columns: ["INTERACTION", 
									  "SELLER_NAME", 
									  "MBTI_SELLER", 
									  "CLUSTER_DENSITY",
									  "DISTANCE_TO_BUYER",
									  "BUYER_NAME",
									  "SCORE_DISTANCE",
									  "SCORE_DENSITY", 
									  "SCORE"],
							values:  [steps, 
									  self.name, 
									  self.my_personality, 
									  buyers_density[buyer.key],
									  buyers_distance_to_me[buyer.key], 
									  buyers(buyer.key).name,
									  buyers_distance_norm[buyer.key],
									  buyers_density_norm[buyer.key], 
									  buyer.value
									]);	
			}
			*/		
		}

		return score_s_n;		
	}
	
	action get_thinking_feeling_score{
		map<buyers, float> score_t_f;
		
		list sellers_perceived <- get_sellers_from_points(sellers_in_my_view);
		
		float inc_num_sellers_close_to_buyer <- 0.0;
		map<buyers, float> num_sellers_close_to_buyer;		
	
		loop buyer over: buyers_in_my_view_global{
			loop seller over: sellers_perceived{
				if(point(seller) distance_to point(buyer) < min_distance_to_exclude){
					inc_num_sellers_close_to_buyer  <- inc_num_sellers_close_to_buyer + 1.0;	
				}
			}
			add buyer::inc_num_sellers_close_to_buyer to:num_sellers_close_to_buyer;
			inc_num_sellers_close_to_buyer <- 0.0;
		}
	
		// We give more weight for feeling agents
		float sellers_close_to_buyer_weight;
		float distance_weight; 
		
		sellers_close_to_buyer_weight <- !self.is_thinking ? 0.8 : 0.2; 
		distance_weight <- 1 - sellers_close_to_buyer_weight ; 
		
		// Normalize num_seller_close_to_buyer as a cost attribute and apply the weight
		map<buyers, float> num_sellers_close_to_buyer_norm;
		num_sellers_close_to_buyer_norm <- num_sellers_close_to_buyer.pairs as_map (each.key::(get_normalized_values(each.value, num_sellers_close_to_buyer, "cost")));		
		
		// Calculate SCORE-T-F
		score_t_f <- buyers_distance_norm_global.pairs as_map (each.key::((each.value*distance_weight)+(num_sellers_close_to_buyer_norm[each.key]*sellers_close_to_buyer_weight)));

		/*
		// Log to the database
			loop buyer over: score_t_f.pairs {
				// log into db the calculated score
				do insert (params: PARAMS,
							into: "TB_SCORE_T_F",
							columns: ["INTERACTION", 
									  "SELLER_NAME", 
									  "MBTI_SELLER", 
									  "NUM_SELLERS_CLOSE_TO_BUYER",
									  "DISTANCE_TO_BUYER",
									  "BUYER_NAME",
									  "SCORE_DISTANCE",
									  "SCORE_SELLER_CLOSE_TO_BUYER", 
									  "SCORE"],
							values:  [steps, 
									  self.name, 
									  self.my_personality, 
									  num_sellers_close_to_buyer[buyer.key],
									  buyers_distance_to_me[buyer.key], 
									  buyers(buyer.key).name,
									  buyers_distance_norm[buyer.key],
									  num_sellers_close_to_buyer_norm[buyer.key], 
									  buyer.value
									]);		
			}
			*/
		
		return score_t_f;		
	}
	
	action get_judging_perceiving_score(list<point> buyers_to_calculate){
		map<buyers, float> new_buyers_score;
		new_buyers_score <- calculate_score(possible_buyers);
				
		if (!empty(new_buyers_score)) {
			map<buyers, float> max_buyer_score <- get_max_score(new_buyers_score);
			new_target <- point(max_buyer_score.keys[0]);
			
			if (target != point(max_buyer_score.keys[0])) {	
				// write "HAS CHANGED THE TARGET";
				// If the target has changed seller must move to this new direction
				target <- new_target;			
				do goto target: target;
				
				/* 			
				// log into db the calculated score
				do insert (params: PARAMS,
							into: "TB_TARGET",
							columns: ["INTERACTION", "TYPE", "SELLER_NAME", "MBTI_SELLER", "BUYER_TARGET", "SCORE"],
							values:  [steps, "NEW TARGET (J-P)", self.name, self.my_personality, max_buyer_score.keys[0], max_buyer_score.values[0]]);		
				*/
			}	
		}
	}
	
	/* 
	action persist_seller_action(buyers buyer_target, point location_target){		
		// log into db the calculated score
		do insert (params: PARAMS,
					into: "TB_SELLER_PRODUCTIVITY",
					columns: ["INTERACTION",  
							  "SELLER_NAME", 
							  "SELLER_ORIGINAL_MBTI", 
							  "SELLER_REAL_MBTI", 
							  "BUYER_TARGET", 
							  "LOCATION_TARGET", 
							  "IS_EXTROVERTED", 
							  "IS_SENSING", 
							  "IS_THINKING", 
							  "IS_JUDGING",
							  "NUMBER_OF_VISITED_BUYERS",
							  "EXPERIMENT_NAME",
							  "SEED"
							  ],
					values:  [steps, 
							  self.name, 
							  self.my_personality, 
							  string(self.my_real_personality), 
							  buyer_target, 
							  location_target, 
							  int(is_extroverted), 
							  int(is_sensing), 
							  int(is_thinking), 
							  int(is_judging),
							  0,
							  world.name,
							  world.seed
					]);
	}
	*/
	  
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
			
			if (buyers(target).my_current_demand = 0){
				do remove_belief(new_predicate("location_buyer", ["location_value"::target]));				
				
				target <- nil;				
				do remove_intention(sell_item, true);
			} else {
				
			do goto target: target;
			
			// If is a perceiveing agent it has 80% probabability to recalcute the plan
			bool must_recalculate_plan;
			must_recalculate_plan <- !self.is_judging ? flip(0.8) : flip(0.2);			
			if(must_recalculate_plan and self.J_P contains_any ["J", "P"]){ do get_judging_perceiving_score(possible_buyers); }			
			
			//if the agent reach its location, it updates it takes the item, updates its belief base, and remove its intention to get item
			if (target = location)  {
				got_buyer <- true;
				
				buyers current_buyer <- buyers first_with (target = each.location);
				if current_buyer != nil and current_buyer.my_current_demand > 0{
					
					// Update demand of the current buyer
					ask current_buyer {
						visited <- true; 
						my_current_demand <- my_current_demand-1;
					}
					
					// Update demand of the current seller
					my_current_demand <- my_current_demand-1;
					
					// If there is no sellers' demand we kill the seller
					if my_current_demand = 0 {
						do die;
					}
				
					// Add number of visits to consider in E-I dichotomy
					add current_buyer::num_visits_to_the_buyer[current_buyer] + 1 to:num_visits_to_the_buyer;
					
					// do persist_seller_action(current_buyer, target);	
					do add_belief(met_buyer);
					add target to: visited_target;
					
					// We need to control the cycle a seller visited a buyer to be able to remove after the limit
					add point(current_buyer)::steps to: buyers_visited_in_cycle;
					
				}
				
				do remove_belief(new_predicate("location_buyer", ["location_value"::target]));				
				
				target <- nil;				
				do remove_intention(sell_item, true);
				} 
			}
		}
	}

	action get_max_score(map<buyers, float> buyer_score){
		return buyer_score.pairs with_max_of(each.value);
	}	
	
	map<buyers, float> calculate_score(list<point> buyers_to_calculate){
		do get_buyers_in_my_view(buyers_to_calculate);
		
		// Calculate score for E-I 
		map<buyers, float> buyers_e_i_score;
		if (self.E_I contains_any ["E", "I"]) {buyers_e_i_score <- get_extroversion_introversion_score();}		
		//if(!turn_off_time) {write "get_extroversion_introversion_score: " + (end_time-start_time);}
		
		// Calculate score for S-N
		map<buyers, float> buyers_s_n_score;
		if (self.S_N contains_any ["S", "N"]) {buyers_s_n_score <- get_sensing_intuition_score();}
		//if(!turn_off_time) {write "get_sensing_intuition_score: " + (end_time-start_time);}
		
		// Calculate score for T-F
		map<buyers, float> buyers_t_f_score;
		if (self.T_F contains_any ["T", "F"]) {buyers_t_f_score <- get_thinking_feeling_score();}		
		//if(!turn_off_time) {write "get_thinking_feeling_score: " + (end_time-start_time);}
		
		// Sum all scores
		map<buyers, float> buyers_score;
		
		buyers_score <- map<buyers, float>(buyers_in_my_view_global collect (each:: (buyers_e_i_score[each]*weight_e_i) +
																					 (buyers_s_n_score[each]*weight_s_n) +
																					 (buyers_t_f_score[each]*weight_t_f)			
		));
										  
		//if(!turn_off_time) {write "sum_all_scores: " + (end_time-start_time);}
	
		return buyers_score;
	}
		
	//plan that has for goal to fulfill the define item target desire. This plan is instantaneous (does not take a complete simulation step to apply).
	plan choose_buyer_target intention: define_buyer_target instantaneous: true{
		possible_buyers <- get_beliefs(new_predicate("location_buyer")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		map<buyers, float> num_visits_to_the_buyer_init <- map<buyers, float>(get_buyers_from_points(possible_buyers) collect (each:: 0.0));
		
		num_visits_to_the_buyer <- map<buyers, float>((num_visits_to_the_buyer_init.keys - num_visits_to_the_buyer.keys) collect (each::num_visits_to_the_buyer_init[each]) 
									+ num_visits_to_the_buyer.pairs);
		
		// If a target was already visited we must removed it
		possible_buyers <- remove_visited_target(possible_buyers);		
		
		// Calculate the scores based on MADM method
		map<buyers, float> buyers_score;
		buyers_score <- calculate_score(possible_buyers);
		
		// It is important to check if there is any buyer to consider because T-F can remove all the possible agents
		if (empty(buyers_score)) {
			do remove_intention(sell_item, true);
			do remove_intention(define_buyer_target, true);
			do add_desire(wander);
		} else {
			
			// We get the max score according to the MADM method			
			map<buyers, float> max_buyer_score <- get_max_score(buyers_score);
			
			// Now find the target buyer from its location
			target <- point(max_buyer_score.keys[0]);
			
			// log into db the calculated score
			//do insert (params: PARAMS,
			//			into: "TB_TARGET",
			//			columns: ["INTERACTION", "TYPE", "SELLER_NAME", "MBTI_SELLER", "BUYER_TARGET", "SCORE"],
			//			values:  [steps, "ORIGINAL", self.name, self.my_personality, max_buyer_score.keys[0], max_buyer_score.values[0]]);						
		}
		do remove_intention(define_buyer_target, true);
	}
	
	aspect default {	  
	  	
	  if(default_aspect_type){draw circle(1) color: color;} 
	  else {draw square(2) color: color;}
	  
	  // enable view distance
	  // draw circle(viewdist_buyers) color:rgb(#yellow,0.5) border: #red;

	  // draw (my_personality) color:#black size:4 at:{location.x-3,location.y+3};
	  
	  //draw ("Agentes ao redor:" + count_people_around) color:#black size:4 at:{location.x,location.y+4};
	  //draw ("Velocidade:" + real_speed) color:#black size:4 at:{location.x,location.y+2}; 
	  //draw ("Demanda:" + my_current_demand) color:#black size:4 at:{location.x,location.y};
	  
	  //write("Intenção Corrente:" + get_values(has_item)  ) ;
	   
	  //draw ("curIntention:" + get_current_intention()) color:#black size:4 at:{location.x,location.y+3*4};
	  //draw ("possible_itens:" + get_current_intention()) color:#black size:4 at:{location.x,location.y+4*4}; 		
	}
	

}


species buyers skills: [moving] schedules: []  {
	rgb color <- #blue;
	bool visited <- false;
	int my_current_demand;
	
	init{
		my_current_demand <- copy(nbitemstobuy);
		// write "My Current Demand " + self.name + " " + my_current_demand;
	}
	
	
	aspect default {  
	  //draw rectangle(30, 15) color: #orange at:{location.x,location.y-20};
	  //draw (string(self.name)) color:#black size:4 at:{location.x-10,location.y-18};
	  
	  
	  //draw triangle(1) color: visited? #green : #blue  at:{location.x,location.y};
	  draw triangle(1) color: my_current_demand=0? #red : #blue at:{location.x,location.y};
	  
	  //draw (string(self.qty_buyers)) color:#white size:4 at:{location.x,location.y}; 
	  //draw buyer_icon size: 40;
	}
}

grid grille_low width: 100 height: 100 {
	rgb color <- #white;
}

grid grille_medium width: 100 height: 100 {
	rgb color <- #white;
}

grid grille_high width: 100 height: 100 {
	rgb color <- #white;
}


experiment LOW_SCENARIO type: gui benchmark: false autorun: false keep_seed: true {
	float minimum_cycle_duration <- 0.00;
	
	// Random Seed Control
	float seedValue <- 1985.0 with_precision 1;
	float seed <- seedValue;
	
	// Global Parameter
	int cycles <- 2;
	int total_items <- 4688; // LOW
	int view_dist <- 15; // LOW
	
	// Low Scenario
	int nbsellers <- 78;
	int nbbuyers <- 313;
	
	string scenario <- "Low";
	
	parameter "Number of Sellers" var: nbsellers <- nbsellers;
	parameter "Number of Buyers" var: nbbuyers <- nbbuyers;
	parameter "Teams Personality" var: teams_mbti_string <- "E,R,R,R";
	parameter "Total Items" var: total_items <- total_items;
	parameter "Items to Sell" var: nbitemstosell <- nbitemstosell;
	parameter "Max Steps" var: max_steps <- cycles;
	parameter "View Distance" var: view_distance <- view_dist;
	parameter "Total Sellers Demand" var: total_sellers_demand;
	parameter "Scenario" var: scenario <- scenario;
	parameter "Market Type" var: market_type <- "Balanced";
	
	output {
		display map {
			grid grille_low lines: #darkgreen;
			species sellers aspect:default;
			species buyers aspect:default;
		}
	}
}


/** 
experiment Batch_MBTI type:batch repeat: 100 keep_seed: false {
	parameter "Number of Sellers" category:"Sellers" var: nbsellers <- 1;
	parameter "Number of Buyers" category:"Buyers" var: nbbuyers <- 1280;
	parameter "Disable time track" category:"General" var: turn_off_time <- true;
	parameter "Disable personality change" category:"General" var: turn_off_personality_probability <- false;

	//output {
	//	display map {
	//		grid grille lines: #darkgreen;
	//		species sellers aspect:default;
	//		species buyers aspect:default;
	//	}		
	//}
	
}
*/