/**
* Name: MBTI1
* MBTI model 
* Author: Luiz Braz
* Tags: 
*/

model MBTI

global {

	int nbsellers <-1;
	int nbbuyers <-50;
	
	int steps <- 0;
	int max_steps <- 1000;
	
	geometry shape <- square(500);
	map<string, string> PARAMS <- ['dbtype'::'sqlite', 'database'::'../../db/mas-mbti-recruitment.db'];
	
	init {
		create buyers number: nbbuyers;

		create sellers number: nbsellers {
			do init(['I','N','F','P']);
		}		
		
		create sellers number: nbsellers {
			do init(['E','S','T','J']);
		}	
	}
	
	reflex stop when:steps=max_steps{
		do pause;
	}
	
	reflex count{
		steps  <- steps + 1;
	}
}

species sellers skills: [moving, SQLSKILL] control: simple_bdi{
	float viewdist_sellers <- 100.0;
	float viewdist_buyers <- 50.0;
	float speed <- 20.0;
	int count_people_around <- 0 ;
	bool got_buyer <- false;

	// MBTI variables
	string my_personality;
	list my_real_personality;
	
	string E_I;
	bool is_extroverted;
	
	string S_N;
	bool is_sensing;
	
	string T_F;
	bool is_thinking;

	string J_P;
	bool is_judging;
	
	bool already_visited_cluster <- false;
	
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

	list<point> visited_target;
	list<point> perceived_buyers;
	
	list<point> sellers_in_my_view;
	
	list<point> possible_buyers;
	
	int weight_qty_buyers <- 100;
	float min_distance_to_exclude <- 50.0;
	
	int weight_intraversion <- -100;
	int weight_extraversion <- 100;
	int weight_sensing <- -100;
	int weight_intuition <- 100;	
	
	action define_personality(list<string> mbti_personality){
		E_I <- mbti_personality at 0;
		S_N <- mbti_personality at 1;
		T_F <- mbti_personality at 2;
		J_P <- mbti_personality at 3;
		
		// An agent has 80% of probabability to keep its original MBTI personality
		is_extroverted<- E_I = 'E' ? flip(0.8) : flip(0.2);
		is_sensing <- S_N =  'S' ? flip(0.8) : flip(0.2);
		is_thinking <- T_F =  'T' ? flip(0.8) : flip(0.2);
		is_judging <- J_P = 'J' ? flip(0.8) : flip(0.2);
		
		write "Agent " + self.name + " has " + mbti_personality + " MBTI original personality";
		write "Agent " + self.name + " is_extroverted: " + is_extroverted;
		write "Agent " + self.name + " is_sensing: " + is_sensing;
		write "Agent " + self.name + " is_thinking: " + is_thinking;
		write "Agent " + self.name + " is_judging: " + is_judging;
		
		add is_extroverted?"E":"I" to: my_real_personality;
		add is_sensing?"S":"N" to: my_real_personality;
		add is_thinking?"T":"F" to: my_real_personality;
		add is_judging?"J":"P" to: my_real_personality;
		
		color <- #blue;		
	}
	
	//at the creation of the agent, we add the desire to patrol (wander)
	action init (list<string> mbti_personality)
	{		
		
		write "init";
		// set my personality
		my_personality <- string(mbti_personality);
		
		// clean table
		do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_SCORE_E_I";
		do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_SCORE_S_N";
		do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_TARGET";
		do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_SELLER_PRODUCTIVITY";
		
		do define_personality(mbti_personality);

		// Begin to wander
		do add_desire(wander);
	}
	
	//if the agent perceive a buyer in its neighborhood, it adds a belief concerning its location and remove its wandering intention
	perceive target:buyers in: viewdist_buyers*2{
		// Seller only focus on buyer if it wasn`t visited yet
		if(!visited){
			focus id:"location_buyer" var:location;
			write "buyer:" + name + " distance to me:" + point(location) distance_to point(myself.location);
			ask myself {do remove_intention(wander, false);	}	
		}		
	}
	
	perceive target:sellers in: viewdist_sellers*2{
		focus id:"location_seller" var:location;
		sellers_in_my_view <- get_beliefs(new_predicate("location_seller")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		do remove_belief(new_predicate("location_seller"));
	}
	
	list get_biggest_cluster(list buyers_in_my_view){	  	
	  	list<list<buyers>> clusters <- list<list<buyers>>(simple_clustering_by_distance(buyers_in_my_view, 30));
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
		remove all:visited_target from: list_of_points;
		return list_of_points;
	}
	
	// TODO: remove after all the scoring methods are done
	action get_norm(float score, map<buyers, float> buyers_scores, bool order_by_asc <- true){
		if min(buyers_scores)=max(buyers_scores) {
			return 1.0 ;
		}
		
		if(order_by_asc){
			return abs((score - min(buyers_scores)) / (max(buyers_scores) - min(buyers_scores)));
		}
		else {
			return abs((score - max(buyers_scores)) / (min(buyers_scores) - max(buyers_scores)));	
		} 
	}
	
	float get_normalized_values(float value, map<buyers, float> buyers_values, string criteria_type){
		if criteria_type="cost"{
			return value>0 ? abs(min(buyers_values) / value) : 1.0;	
		} else {
			return abs(value / max(buyers_values));
		}
	}
	
	map<buyers, float> get_distances(list<buyers> buyers_in_my_view){
		return map<buyers, float>(buyers_in_my_view collect (each::self distance_to (each)));
	}
	
	map<buyers, float> get_distances_norm(list<buyers> buyers_in_my_view){
		return map<buyers, float>(buyers_in_my_view collect (each::self distance_to (each)));
	}
	
	map<buyers, float> get_buyers_size(list<buyers> buyers_in_my_view){
		return map<buyers, float>(buyers_in_my_view collect (each::each.qty_buyers));		
	}
	
	action get_extroversion_introversion_score(list list_of_points){
		map<buyers, float> score_e_i;
		
		list<buyers> buyers_in_my_view <- get_buyers_from_points(list_of_points);
		
		// When there is a unique agent we can simply consider it as the max score
		if(length(buyers_in_my_view)=1){
			score_e_i <-  map<buyers, float>(buyers_in_my_view collect (first(each)::1.0));
		}
		else {			
		
			buyers_in_my_view <- reverse (buyers_in_my_view sort_by (each distance_to self));
				
			map<buyers, float> buyers_distance_to_me;
			map<buyers, float> buyers_distance_norm;
			
			// Get the distance of each buyer to the seller and calculate the inverted norm score
			buyers_distance_to_me  <- get_distances(buyers_in_my_view); 
			buyers_distance_norm <- buyers_distance_to_me.pairs as_map (each.key::(get_normalized_values(each.value, buyers_distance_to_me, "cost")));
			
			map<buyers, float> buyers_size;
			map<buyers, float> buyers_size_norm;
			
			// Get how many people exists in the buyer
			buyers_size <- get_buyers_size(buyers_in_my_view);
			
			string criteria_type;
			
			// According to the seller personality type the normalization procedure will change (cost or benefit attribute) 
			criteria_type <- !self.is_extroverted ? "cost" : "benefit";			 
			buyers_size_norm <- buyers_size.pairs as_map (each.key::float(get_normalized_values(each.value, buyers_size, criteria_type)));			
			
			// Calculate SCORE-E-I
			score_e_i <- buyers_distance_norm.pairs as_map (each.key::each.value+(buyers_size_norm[each.key]));
			
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
			
			return score_e_i;	
		}
	}	

	
	// TODO: calculate according to MADM procedure
	action get_sensing_intuition_score(list list_of_points){
		map<buyers, float> agents_score;
		list<buyers> buyers_in_my_view <- get_buyers_from_points(list_of_points);
		
		// When there is a unique agent we can simply consider it as the max score
		if(length(buyers_in_my_view)=1){
			agents_score <-  map<buyers, float>(buyers_in_my_view collect (first(each)::1.0));
		}
		else {
		
			map<buyers, float> buyers_distance_to_me;
			map<buyers, float> buyers_distance_score;
				
			// Get the distance of each buyer to the seller and calculate the inverted norm score
			// buyers_distance_to_me  <- map<buyers, float>(buyers_in_my_view collect (each::self distance_to (each)));
			buyers_distance_to_me <- get_distances(buyers_in_my_view);
			
			buyers_distance_score <- buyers_distance_to_me.pairs as_map (each.key::float(get_norm(each.value, buyers_distance_to_me, false)));
				
			list<list<buyers>> clusters <- list<list<buyers>>(simple_clustering_by_distance(buyers_in_my_view, 30));
			int min_cluster <- min(clusters collect (length(each)));
			int max_cluster <- max(clusters collect (length(each)));
			
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
			
			// Get the distance of each buyer to the seller and calculate the inverted norm score
			map<buyers, float> buyers_density_score;
			buyers_density_score <- buyers_density.pairs as_map (each.key:: (max(buyers_density)>1) ? float(get_norm(each.value, buyers_density)) : 1.0);			
			
			// Use the right weight depend on the seller personality and calculate the combined score
			if(!self.is_sensing){
				agents_score <- buyers_distance_score.pairs as_map (each.key::each.value+(weight_intuition*buyers_density_score[each.key]));
			}else {
				agents_score <- buyers_distance_score.pairs as_map (each.key::each.value+(weight_sensing*buyers_density_score[each.key]));
			}
			
			// Calculate the final norm score
			agents_score <- agents_score.pairs as_map (each.key::float(get_norm(each.value, agents_score)));
		
			float score;
			  
			// Log to the database
			loop buyer over: agents_score.pairs {
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
									  buyers_distance_score[buyer.key],
									  buyers_density_score[buyer.key], 
									  buyer.value
									]);		
			}		
		}
		
		return agents_score;		
	}
	
	// TODO: calculate according to MADM procedure
	action get_thinking_feeling_score(list list_of_points, map<buyers, float> buyers_score_t_f){
		list sellers_perceived <- get_sellers_from_points(sellers_in_my_view);
	
		loop seller over: sellers_perceived{
			loop buyer over: buyers_score_t_f.pairs{
				
				// if the buyers is in a minimal distance to the colleages we exclude it
				// TODO: consider teamates
				if(point(seller) distance_to point(buyer.key) < min_distance_to_exclude){
					remove all: buyer from: buyers_score_t_f;	
				}
			}
		}
		
		return buyers_score_t_f;		
	}
	
	// TODO: calculate according to MADM procedure
	action get_judging_perceiving_score(list<point> buyers_to_calculate){
		map<buyers, float> new_buyers_score;
		new_buyers_score <- calculate_score(possible_buyers);
				
		if (!empty(new_buyers_score)) {
			map<buyers, float> max_buyer_score <- get_max_score(new_buyers_score);
			new_target <- point(max_buyer_score.keys[0]);
			
			if (target != point(max_buyer_score.keys[0])) {
				write "Target has changed because J-P: before " + target + " after " + new_target ;
				write "new_buyers_score: " + new_buyers_score;
				write "max_buyer_score:" + max_buyer_score;
				write "max_buyer_score.values[0]: " + max_buyer_score.values[0];
	
				// If the target has changed seller must move to this new direction
				target <- new_target;			
				do goto target: target;
							
				// log into db the calculated score
				do insert (params: PARAMS,
							into: "TB_TARGET",
							columns: ["INTERACTION", "TYPE", "SELLER_NAME", "MBTI_SELLER", "BUYER_TARGET", "SCORE"],
							values:  [steps, "NEW TARGET (J-P)", self.name, self.my_personality, max_buyer_score.keys[0], max_buyer_score.values[0]]);		
			}	
		}
	}
	
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
							  "IS_JUDGING"],
					values:  [steps, 
							  self.name, 
							  self.my_personality, 
							  self.my_real_personality, 
							  buyer_target, 
							  location_target, 
							  int(is_extroverted), 
							  int(is_sensing), 
							  int(is_thinking), 
							  int(is_judging)
					]);
	}
	  
	//if the agent has the belief that there is a possible buyer given location, it adds the desire to interact with the buyer to try to sell items.
	rule belief: new_predicate("location_buyer") new_desire: sell_item strength:10.0;

	//if the agent has the belief that there is a possible buyer given location, it adds the desire to interact with the buyer to try to sell items.
	//rule belief: new_predicate("location_seller") new_desire: say_something strength:10.0;


	// plan that has for goal to fulfill the wander desire	
	plan letsWander intention:wander 
	{
		do wander amplitude: 60.0 speed: speed;
	}
	
	//plan saySomething intention: say_something{
	//	write "Say Something";
	//} 
	
	// plan that has for goal to fulfill the "sell_item" desire
	plan sellItem intention:sell_item{
		// if the agent does not have chosen a target location, it adds the sub-intention to define a target and puts its current intention on hold
		// the agent will do the same if it has the perceiveing personality, because it has to reconsider it current decision each cycle 
		if (target = nil) {
			do add_subintention(get_current_intention(), define_buyer_target, true);
			do current_intention_on_hold(); 
		} else {
			
			do goto target: target;
			
			// If is a perceiveing agent the target can change each cycle
			if(!self.is_judging){
				do get_judging_perceiving_score(possible_buyers);
			}			
			
			
			//if the agent reach its location, it updates it takes the item, updates its belief base, and remove its intention to get item
			if (target = location)  {
				got_buyer <- true;
				
				buyers current_buyer <- buyers first_with (target = each.location);
				if current_buyer != nil {
					ask current_buyer {visited <- true;}
					// persist into the db the seller`s action
					do persist_seller_action(current_buyer, target);	
					do add_belief(met_buyer);			 	
				}
				
				do remove_belief(new_predicate("location_buyer", ["location_value"::target]));
				add target to: visited_target;
				
				target <- nil;				
				do remove_intention(sell_item, true);
			}
		}
	}

	action get_max_score(map<buyers, float> buyer_score){
		return buyer_score.pairs with_max_of(each.value);
	}
	
	map<buyers, float> calculate_score(list<point> buyers_to_calculate){
		map<buyers, float> buyers_e_i_score;
		
		buyers_e_i_score <- get_extroversion_introversion_score(buyers_to_calculate);
		
		map<buyers, float> buyers_s_n_score;
		
		// Calculate score for intuition agents
		if(!is_sensing){
			buyers_s_n_score <- get_sensing_intuition_score(buyers_to_calculate);
		} else {
			buyers_s_n_score <- map<buyers, float>(buyers_to_calculate collect (each));
		}
		
		map<buyers, float> buyers_score;
		
		// Sum scores E-I and S-N		
		buyers_score <- map<buyers, float>(buyers_e_i_score.pairs collect (each.key::each.value + buyers_s_n_score[each.key]));
		
		buyers_score <- get_thinking_feeling_score(possible_buyers, buyers_score);
		
		return buyers_score;
	}
		
	//plan that has for goal to fulfill the define item target desire. This plan is instantaneous (does not take a complete simulation step to apply).
	plan choose_buyer_target intention: define_buyer_target instantaneous: true{
		possible_buyers <- get_beliefs(new_predicate("location_buyer")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	
		possible_buyers <- remove_visited_target(possible_buyers);
		
		map<buyers, float> buyers_score;
		buyers_score <- calculate_score(possible_buyers);
		
		// It is important to check if there is any buyer to consider because T-F can remove all the possible agents
		if (empty(buyers_score)) {
			do remove_intention(sell_item, true);
			do remove_intention(define_buyer_target, true);
			do add_desire(wander);
		} else {
			
			map<buyers, float> max_buyer_score <- get_max_score(buyers_score);
			target <- point(max_buyer_score.keys[0]);
			
			// log into db the calculated score
			do insert (params: PARAMS,
						into: "TB_TARGET",
						columns: ["INTERACTION", "TYPE", "SELLER_NAME", "MBTI_SELLER", "BUYER_TARGET", "SCORE"],
						values:  [steps, "ORIGINAL", self.name, self.my_personality, max_buyer_score.keys[0], max_buyer_score.values[0]]);
						
			if(!already_visited_cluster) {
				already_visited_cluster <- true;
			} 			
		}
		do remove_intention(define_buyer_target, true);
	}
	
	aspect default {	  
	  	
	  draw circle(18) color: color;
	  
	  // enable view distance
	  //draw circle(viewdist_buyers*2) color:rgb(#white,0.5) border: #red;

	  if(is_extroverted){
	  	draw ("MBTI:E" ) color:#black size:4;
	  } else{
	  	draw ("MBTI:I" ) color:#black size:4;
	  }

	  //draw ("Agentes ao redor:" + count_people_around) color:#black size:4 at:{location.x,location.y+4};
	  //draw ("Velocidade:" + speed) color:#black size:4 at:{location.x,location.y+2*4}; 
	  
	  //write("Intenção Corrente:" + get_values(has_item)  ) ;
	   
	  //draw ("B:" + length(belief_base) + ":" + belief_base) color:#black size:4; 
	  //draw ("D:" + length(desire_base) + ":" + desire_base) color:#black size:4 at:{location.x,location.y+4}; 
	  //draw ("I:" + length(intention_base) + ":" + intention_base) color:#black size:4 at:{location.x,location.y+2*4}; 
	  //draw ("curIntention:" + get_current_intention()) color:#black size:4 at:{location.x,location.y+3*4};
	  //draw ("possible_itens:" + get_current_intention()) color:#black size:4 at:{location.x,location.y+4*4}; 		
	}
}


species buyers skills: [moving] control: simple_bdi {	
	rgb color <- #blue;
	float speed <- 3.0;
	bool visited <- false;
	int qty_buyers <- rnd (1, 30);
	
	image_file buyer_icon <- image_file("../../includes/buyer.png");
	
	predicate wander <- new_predicate("wander");
	
	//at the creation of the agent, we add the desire to patrol (wander)
	init
	{		
		// do add_desire(wander);
	}
	
	// plan that has for goal to fulfill the wander desire	
	plan letsWander intention:wander 
	{
		do wander amplitude: 60.0 speed: speed;
	}
	
	aspect default {  
	  draw rectangle(30, 15) color: #orange at:{location.x,location.y-20};
	  draw (string(self.name)) color:#black size:4 at:{location.x-10,location.y-18};
	  draw circle(5) color: visited? #green : #blue  at:{location.x,location.y+20};
	  draw (string(self.qty_buyers)) color:#white size:4 at:{location.x-3,location.y+22}; 
	  draw buyer_icon size: 40;
	}
}

grid grille width: 40 height: 40 neighbors:4 {
	rgb color <- #white;
}

experiment MBTI type: gui {
	float minimum_cycle_duration <- 0.05;
	/** Insert here the definition of the input and output of the model */
	output {
		display map {
			grid grille lines: #darkgreen;
			species sellers aspect:default;
			species buyers aspect:default;
		}		
	}
}

