/**
* Name: MBTI1
* MBTI model 
* Author: Luiz Braz
* Tags: 
*/

model MBTI

global {


	int iteration_number <- 1;

	int nbsellers;
	int nbbuyers;
	bool turn_off_time;
	bool turn_off_personality_probability;
	list<point> visited_target;
		
	int steps <- 0;
	int max_steps <- 5000; // CHANGED
	
	int num_visited_target_ENFJ <- 0;
	int num_visited_target_ENFP <- 0;
	int num_visited_target_ENTJ <- 0;
	int num_visited_target_ENTP <- 0;
	int num_visited_target_ESFJ <- 0;
	int num_visited_target_ESFP <- 0;
	int num_visited_target_ESTJ <- 0;
	int num_visited_target_ESTP <- 0;
	int num_visited_target_INFJ <- 0;
	int num_visited_target_INFP <- 0;
	int num_visited_target_INTJ <- 0;
	int num_visited_target_INTP <- 0;
	int num_visited_target_ISFJ <- 0;
	int num_visited_target_ISFP <- 0;
	int num_visited_target_ISTJ <- 0;
	int num_visited_target_ISTP <- 0;

	geometry shape <- square(500);
	// map<string, string> PARAMS <- ['dbtype'::'sqlite', 'database'::'../../db/mas-mbti-recruitment.db'];
	// map<string, string> PARAMS_SQL <- ['host'::hostname, 'dbtype'::'sqlserver', 'database'::'TESTEDB', 'port'::'1433', 'user'::'gama_user', 'passwd'::'gama#123'];
	map<string, string> PARAMS <- ['host'::'localhost', 'dbtype'::'Postgres', 'database'::'gama_data', 'port'::'5432', 'user'::'postgres_user', 'passwd'::'gama#123'];
	
	init {
		write "new simulation created: " + name;
		
		create buyers number: nbbuyers;
		write "Buyers: " + nbbuyers;
		
		 
		create sellers number: nbsellers {
			do init(['E','S','F','J'] );
		}
		
		create sellers number: nbsellers {
			do init(['E','S','F','P']);
		}		
		
		create sellers number: nbsellers {
			do init(['E','S','T','J']);
		}
		
		create sellers number: nbsellers {
			do init(['E','S','T','P']);
		}
		
		create sellers number: nbsellers {
			do init(['E','N','F','J']);
		}
		
		create sellers number: nbsellers {
			do init(['E','N','F','P']);
		}
		
		create sellers number: nbsellers {
			do init(['E','N','T','J']);
		}
		
		create sellers number: nbsellers {
			do init(['E','N','T','P']);
		}
		
		create sellers number: nbsellers {
			do init(['I','S','F','J']);
		}

		create sellers number: nbsellers {
			do init(['I','S','F','P']);
		}
		
		create sellers number: nbsellers {
			do init(['I','S','T','J']);
		}
		
		create sellers number: nbsellers {
			do init(['I','S','T','P']);
		}
		
		create sellers number: nbsellers {
			do init(['I','N','F','J']);
		}
		
		create sellers number: nbsellers {
			do init(['I','N','F','P']);
		}
		
		create sellers number: nbsellers {
			do init(['I','N','T','J']);
		}
		
		create sellers number: nbsellers {
			do init(['I','N','T','P']);
		}
			
	}
	
	reflex stop when:steps=max_steps{
		do die;		
	}
	
	reflex count{
		write "Performing step: " + steps;
		steps  <- steps + 1;
	}
}

species sellers skills: [moving, SQLSKILL] control: simple_bdi{
	float viewdist_buyers <- 50.0;
	//float speed <- 20.0;
	int count_people_around <- 0 ;
	bool got_buyer <- false;

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
	
	float min_distance_to_exclude <- 50.0;
	
	float weight_e_i <- 1/3;
	float weight_s_n <- 1/3;
	float weight_t_f <- 1/3;
	
	int cluster_distance <- 30;	
	
	date start_time;
	date end_time;
	
	int number_of_visited_buyers <- 0;
	
	string experiment_name;

	list<buyers> buyers_in_my_view_global;
	map<buyers, float> buyers_distance_to_me_global;
	map<buyers, float> buyers_distance_norm_global;
			
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
		
		// An seller agent has 80% of probabability to keep its original MBTI personality
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
	
	
	//at the creation of the agent, we add the desire to patrol (wander)
	action init (list<string> mbti_personality)
	{		
        
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
		 do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_SELLER_PRODUCTIVITY WHERE EXPERIMENT_NAME=?" values: [world.name]; // CHANGED
		
		//do executeUpdate params: PARAMS updateComm: "TRUNCATE TABLE TB_SELLER_PRODUCTIVITY"; 
		
		//do define_personality(mbti_personality);
		do define_personality_without_prob(mbti_personality);

		// Begin to wander
		do add_desire(wander);
	}
	
	// We use the param each cycle to know when to use the define_personality function 
	reflex get_current_personality{
		my_current_personality <- list(self.my_personality);
		if(turn_off_personality_probability) {do define_personality(my_current_personality);}
	}
	
	//if the agent perceive a buyer in its neighborhood, it adds a belief concerning its location and remove its wandering intention
	perceive target:buyers in: viewdist_buyers{
		// Seller only focus on buyer if it wasn`t visited yet
		if(!self.visited){
			focus id:"location_buyer" var:location;
			ask myself {do remove_intention(wander, false);	}	
		}		
	}
	
	//perceive target:sellers in: viewdist_sellers*2{
	//	focus id:"location_seller" var:location;
	//	sellers_in_my_view <- get_beliefs(new_predicate("location_seller")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
	//	do remove_belief(new_predicate("location_seller"));
	//}
	
	// TODO: consider teamates
	perceive target:sellers in: viewdist_buyers{
		// We must validate that only our teammates would be considered (also remove the seller itself)
		if(myself.name != self.name){
			focus id:"location_seller" var:location;
			sellers_in_my_view <- get_beliefs(new_predicate("location_seller")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
			do remove_belief(new_predicate("location_seller"));		
		}
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
		remove all:visited_target from: list_of_points;
		return list_of_points;
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
	
	action get_buyers_in_my_view(list list_of_buyers){
		buyers_in_my_view_global <- get_buyers_from_points(list_of_buyers);
		buyers_in_my_view_global <- reverse (buyers_in_my_view_global sort_by (each distance_to self));
		
		// Get the distance of each buyer to the seller and calculate the inverted norm score
		buyers_distance_to_me_global  <- get_distances(buyers_in_my_view_global); 
		buyers_distance_norm_global <- buyers_distance_to_me_global.pairs as_map (each.key::(get_normalized_values(each.value, buyers_distance_to_me_global, "cost")));
	}
	
	action get_extroversion_introversion_score(list list_of_points){
		map<buyers, float> score_e_i;
		
		//list<buyers> buyers_in_my_view <- get_buyers_from_points(list_of_points);
		
		// When there is a unique agent we can simply consider it as the max score
		if(length(buyers_in_my_view_global)=1){
			score_e_i <-  map<buyers, float>(buyers_in_my_view_global collect (first(each)::1.0));
		}
		else {			
		
			// buyers_in_my_view <- reverse (buyers_in_my_view sort_by (each distance_to self));
				
			// map<buyers, float> buyers_distance_to_me;
			// map<buyers, float> buyers_distance_norm;
			
			// Get the distance of each buyer to the seller and calculate the inverted norm score
			// buyers_distance_to_me  <- get_distances(buyers_in_my_view); 
			// buyers_distance_norm <- buyers_distance_to_me.pairs as_map (each.key::(get_normalized_values(each.value, buyers_distance_to_me, "cost")));
			
			map<buyers, float> buyers_size;
			map<buyers, float> buyers_size_norm;
			
			// Get how many people exists in the buyer
			buyers_size <- get_buyers_size(buyers_in_my_view_global);
			
			string criteria_type;
			
			// According to the seller personality type the normalization procedure will change (cost or benefit attribute) 
			criteria_type <- !self.is_extroverted ? "cost" : "benefit";			 
			buyers_size_norm <- buyers_size.pairs as_map (each.key::float(get_normalized_values(each.value, buyers_size, criteria_type)));			
			
			// Calculate SCORE-E-I
			score_e_i <- buyers_distance_norm_global.pairs as_map (each.key::each.value+(buyers_size_norm[each.key]));
			
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

	action get_sensing_intuition_score(list list_of_points){
		map<buyers, float> score_s_n;
		//list<buyers> buyers_in_my_view <- get_buyers_from_points(list_of_points);
		
		// When there is a unique agent we can simply consider it as the max score
		if(length(buyers_in_my_view_global)=1){
			score_s_n <-  map<buyers, float>(buyers_in_my_view_global collect (first(each)::1.0));
		}
		else {
		
			//map<buyers, float> buyers_distance_to_me;
			//map<buyers, float> buyers_distance_norm;
				
			// Get the distance of each buyer to the seller and calculate the inverted norm score
			//buyers_distance_to_me <- get_distances(buyers_in_my_view);
			//buyers_distance_norm <- buyers_distance_to_me.pairs as_map (each.key::(get_normalized_values(each.value, buyers_distance_to_me, "cost")));			
			
			// Calculate the density using simple_clustering_by_distance technique
			list<list<buyers>> clusters <- list<list<buyers>>(simple_clustering_by_distance(buyers_in_my_view_global, 30));
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
			
			density_weight <- self.is_sensing ? 0.8 : 0.2; 
			distance_weight <- 1 - density_weight; 
			
			// Normalize density as a benefit attribute
			map<buyers, float> buyers_density_norm;
			buyers_density_norm <- buyers_density.pairs as_map (each.key::(max(buyers_density)>1) ? get_normalized_values(each.value, buyers_density, "benefit") : 1.0);
			
			// Calculate SCORE-S-N
			score_s_n <- buyers_distance_norm_global.pairs as_map (each.key::((each.value*distance_weight)+(buyers_density_norm[each.key]*density_weight)));
			
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
	
	action get_thinking_feeling_score(list list_of_points){
		map<buyers, float> score_t_f;
		//list<buyers> buyers_in_my_view <- get_buyers_from_points(list_of_points);
		
		list sellers_perceived <- get_sellers_from_points(sellers_in_my_view);
		
		//map<buyers, float> buyers_distance_to_me;
		//map<buyers, float> buyers_distance_norm;
				
		// Get the distance of each buyer to the seller and calculate the inverted norm score
		//buyers_distance_to_me <- get_distances(buyers_in_my_view);		
		//buyers_distance_norm <- buyers_distance_to_me.pairs as_map (each.key::(get_normalized_values(each.value, buyers_distance_to_me, "cost")));
		
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
							  self.number_of_visited_buyers,
							  world.name,
							  world.seed
					]);
	}
	  
	//if the agent has the belief that there is a possible buyer given location, it adds the desire to interact with the buyer to try to sell items.
	rule belief: new_predicate("location_buyer") new_desire: sell_item strength:10.0;

	//if the agent has the belief that there is a possible buyer given location, it adds the desire to interact with the buyer to try to sell items.
	//rule belief: new_predicate("location_seller") new_desire: say_something strength:10.0;


	// plan that has for goal to fulfill the wander desire	
	plan letsWander intention:wander 
	{
		do wander amplitude: 60.0;
		// speed: speed;
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
			
			// If is a perceiveing agent it has 80% probabability to recalcute the plan
			bool must_recalculate_plan;
			must_recalculate_plan <- !self.is_judging ? flip(0.8) : flip(0.2);			
			if(must_recalculate_plan){ do get_judging_perceiving_score(possible_buyers); }			
			
			//if the agent reach its location, it updates it takes the item, updates its belief base, and remove its intention to get item
			if (target = location)  {
				got_buyer <- true;
				
				buyers current_buyer <- buyers first_with (target = each.location);
				if current_buyer != nil and !current_buyer.visited{
					ask current_buyer {visited <- true;}
					number_of_visited_buyers <- number_of_visited_buyers + 1;
					// persist into the db the seller`s action
					
					switch string(self.my_real_personality) {
						match "['E','N','F','J']" {
							num_visited_target_ENFJ <- num_visited_target_ENFJ+1;
						}
						match "['E','N','F','P']" {
							num_visited_target_ENFP <- num_visited_target_ENFP+1;
						}
						match "['E','N','T','J']" {
							num_visited_target_ENTJ <- num_visited_target_ENTJ+1;
						}
						match "['E','N','T','P']" {
							num_visited_target_ENTP <- num_visited_target_ENTP+1;							
						}
						match "['E','S','F','J']" {
							num_visited_target_ESFJ <- num_visited_target_ESFJ+1;
						}
						match "['E','S','F','P']" {
							num_visited_target_ESFP <- num_visited_target_ESFP+1;
						}
						match "['E','S','T','J']" {
							num_visited_target_ESTJ <- num_visited_target_ESTJ+1;
						}
						match "['E','S','T','P']" {
							num_visited_target_ESTP <- num_visited_target_ESTP+1;
						}
						match "['I','N','F','J']" {
							num_visited_target_INFJ <- num_visited_target_INFJ+1;
						}
						match "['I','N','F','P']" {
							num_visited_target_INFP <- num_visited_target_INFP+1;
						}
						match "['I','N','T','J']" {
							num_visited_target_INTJ <- num_visited_target_INTJ+1;
						}
						match "['I','N','T','P']" {
							num_visited_target_INTP <- num_visited_target_INTP+1;
						}
						match "['I','S','F','J']" {
							num_visited_target_ISFJ <- num_visited_target_ISFJ+1;
						}
						match "['I','S','F','P']" {
							num_visited_target_ISFP <- num_visited_target_ISFP+1;
						}
						match "['I','S','T','J']" {
							num_visited_target_ISTJ <- num_visited_target_ISTJ+1;
						}
						match "['I','S','T','P']" {
							num_visited_target_ISTP <- num_visited_target_ISTP+1;
						} 
					}
					
					// do persist_seller_action(current_buyer, target);	
					do add_belief(met_buyer);
					add target to: visited_target;
				}
				
				do remove_belief(new_predicate("location_buyer", ["location_value"::target]));				
				
				target <- nil;				
				do remove_intention(sell_item, true);
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
		buyers_e_i_score <- get_extroversion_introversion_score(buyers_to_calculate);		
		if(!turn_off_time) {write "get_extroversion_introversion_score: " + (end_time-start_time);}
		
		// Calculate score for S-N
		map<buyers, float> buyers_s_n_score;
		buyers_s_n_score <- get_sensing_intuition_score(buyers_to_calculate);
		if(!turn_off_time) {write "get_sensing_intuition_score: " + (end_time-start_time);}
		
		// Calculate score for T-F
		map<buyers, float> buyers_t_f_score;
		buyers_t_f_score <- get_thinking_feeling_score(possible_buyers);		
		if(!turn_off_time) {write "get_thinking_feeling_score: " + (end_time-start_time);}
		
		// Sum all scores
		map<buyers, float> buyers_score;
		buyers_score <- map<buyers, float>(buyers_e_i_score.pairs collect (each.key::((each.value*weight_e_i) + 
																					  (buyers_s_n_score[each.key]*weight_s_n) + 
																					  (buyers_t_f_score[each.key]*weight_t_f))));
		if(!turn_off_time) {write "sum_all_scores: " + (end_time-start_time);}
		
		return buyers_score;
	}
		
	//plan that has for goal to fulfill the define item target desire. This plan is instantaneous (does not take a complete simulation step to apply).
	plan choose_buyer_target intention: define_buyer_target instantaneous: true{
		possible_buyers <- get_beliefs(new_predicate("location_buyer")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		
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
	  	
	  draw circle(10) color: color;
	  
	  // enable view distance
	  //draw circle(viewdist_buyers*2) color:rgb(#white,0.5) border: #red;

	  //if(is_extroverted){draw ("MBTI:E" ) color:#black size:4;}
	  
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


	

species buyers skills: [moving] schedules: []  {	
	rgb color <- #blue;
	float speed <- 3.0;
	bool visited <- false;
	int qty_buyers <- rnd (1, 30);
	
	//image_file buyer_icon <- image_file("../../includes/buyer.png");	
	
	aspect default {  
	  //draw rectangle(30, 15) color: #orange at:{location.x,location.y-20};
	  //draw (string(self.name)) color:#black size:4 at:{location.x-10,location.y-18};
	  draw circle(5) color: visited? #green : #blue  at:{location.x,location.y+20};
	  //draw (string(self.qty_buyers)) color:#white size:4 at:{location.x-3,location.y+22}; 
	  //draw buyer_icon size: 40;
	}
}

// CHANGED
grid grille width: 160 height: 160 {
	rgb color <- #white;
}


experiment MBTI type: gui benchmark: false  {
	float minimum_cycle_duration <- 0.00;
	
	// Random Seed Control
	//float seed <- 2014.0; 
	//float seed <- 2015.0;
	//float seed <- 2016.0;
	//float seed <- 2017.0;
	//float seed <- 2018.0;
	
	parameter "Number of Sellers" category:"Sellers" var: nbsellers <- 1 among: [1,3,5,10,15,20];
	parameter "Number of Buyers" category:"Buyers" var: nbbuyers <- 50 among: [10,50,100,200,400,500, 1280, 6400, 24320]; // CHANGED
	parameter "Disable time track" category:"General" var: turn_off_time <- true;
	parameter "Disable personality change" category:"General" var: turn_off_personality_probability <- false;
	
	//reflex t when: every(10#cycle) {
	//	do compact_memory;
	//}
	
	/** Insert here the definition of the input and output of the model */
	output {
		display map {
			grid grille lines: #darkgreen;
			species sellers aspect:default;
			species buyers aspect:default;
		}
		
		/** 
		display "sellers_performance" type: java2D{
        	chart "Seller's performance" type: series y_tick_unit: 1 x_label: 'Cycles' label_font: font('Serif', 14 #plain) y_label: 'Number of visited buyers' {        		
        	data "ENFJ" value: num_visited_target_ENFJ style: spline;
        	data "ENFP" value: num_visited_target_ENFP style: spline;
        	data "ENTJ" value: num_visited_target_ENTJ style: spline;
        	data "ENTP" value: num_visited_target_ENTP style: spline;
        	data "ESFJ" value: num_visited_target_ESFJ style: spline;
        	data "ESFP" value: num_visited_target_ESFP style: spline;
        	data "ESTJ" value: num_visited_target_ESTJ style: spline;
        	data "ESTP" value: num_visited_target_ESTP style: spline;
        	data "INFJ" value: num_visited_target_INFJ style: spline;
        	data "INFP" value: num_visited_target_INFP style: spline;
        	data "INTJ" value: num_visited_target_INTJ style: spline;
        	data "INTP" value: num_visited_target_INTP style: spline;
        	data "ISFJ" value: num_visited_target_ISFJ style: spline;
        	data "ISFP" value: num_visited_target_ISFP style: spline;
        	data "ISTJ" value: num_visited_target_ISTJ style: spline;
        	data "ISTP" value: num_visited_target_ISTP style: spline;
        	}
    	}
    	*/ 	
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