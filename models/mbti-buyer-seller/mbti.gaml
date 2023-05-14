/**
* Name: mbti
* A model implementation inspired on MBTI personality type theory. 
* Author: lubraz
* Tags: 
*/


model mbti


species Person skills: [moving]{
	
	// Weights for each dichtomy considered in MADM matrix
	float weight_e_i <- 1/3;
	float weight_s_n <- 1/3;
	float weight_t_f <- 1/3;
	
	// E-I constraints
	int number_of_cycles_to_return_interacted_agent <- 75;
	int max_number_of_visits_to_a_interacted_agent <- 3;
	//int number_of_cycles_to_return_interacted_agent;
	//int max_number_of_visits_to_a_interacted_agent;
	
    // T-F constraints
    //int min_distance_to_exclude <- 10;
    int min_distance_to_exclude;
								 	
	list my_personality;
	list<string> my_original_personality;
	
	bool is_extroverted;
	bool is_sensing; 
	bool is_thinking;
	bool is_judging;
	
	string E_I;
	string S_N;
	string T_F;
	string J_P;
	
	map<agent, float> num_interactions_with_the_agent;
	map<point, float> agent_distance_norm_global;
	list<point> interacted_target;
	map<point, int> agents_interacted_within_cycle;
	map<agent, float> agents_distance_norm_global;
	
	list<agent> colleagues_in_my_view;
	bool must_use_probability;
	
	reflex must_change_personality when: every(25#cycle) and must_use_probability {
		do set_my_personality(self.my_original_personality, true);
	}
	
	//reflex show_personality {
	//	do show_my_personality();
	//}
	
	list set_my_personality(list<string> mbti_personality,
							bool use_probability
	){
		
		list<string> mbti_personality_treated <- copy(mbti_personality);
		self.my_original_personality <- mbti_personality_treated;
		must_use_probability <- use_probability;
		
		// Check if the MBTI should be randomized
		if(mbti_personality contains "R"){
			mbti_personality_treated <- randomize_personality(mbti_personality);
		}
		
		E_I <- mbti_personality_treated at 0;
		S_N <- mbti_personality_treated at 1;
		T_F <- mbti_personality_treated at 2;
		J_P <- mbti_personality_treated at 3;
				
		self.my_personality <- [];
	
		if (use_probability){
			// An seller agent has 80% of probabability to keep its original MBTI personality
			is_extroverted <- E_I = 'E' ? flip(0.8) : flip(0.2);
			is_sensing <- S_N =  'S' ? flip(0.8) : flip(0.2);
			is_thinking <- T_F =  'T' ? flip(0.8) : flip(0.2);
			is_judging <- J_P = 'J' ? flip(0.8) : flip(0.2);
		}
		else{
			is_extroverted <- E_I = 'E' ? true : false;
			is_sensing <- S_N =  'S' ? true : false;
			is_thinking <- T_F =  'T' ? true : false;
			is_judging <- J_P = 'J' ? true : false;		
		}
		
		add is_extroverted ? "E":"I" to: self.my_personality;
		add is_sensing ? "S":"N" to: self.my_personality;
		add is_thinking ? "T":"F" to: self.my_personality;
		add is_judging ? "J":"P" to: self.my_personality;
				
		return self.my_personality;
	}
	
	list<string> randomize_personality (list<string> mbti_personality) {
		if mbti_personality[0] = 'R' {
				mbti_personality[0] <- rnd_choice(["E"::0.5, "I"::0.5]);
		}
		
		if mbti_personality[1] = 'R' {
				mbti_personality[1] <- rnd_choice(["S"::0.5, "N"::0.5]);
		}
		
		if mbti_personality[2] = 'R' {
				mbti_personality[2] <- rnd_choice(["T"::0.5, "F"::0.5]);
		}
	
		if mbti_personality[3] = 'R' {
				mbti_personality[3] <- rnd_choice(["J"::0.5, "P"::0.5]);
		}
		
		return mbti_personality;	
	}
	
	action set_global_parameters(int nb_number_of_cycles_to_return_interacted_agent, // E-I constraints
								 int nb_max_number_of_visits_to_a_interacted_agent, // E-I constraints
								 int nb_min_distance_to_exclude // T-F constraints
								 ){
	
	number_of_cycles_to_return_interacted_agent <- nb_number_of_cycles_to_return_interacted_agent;
	max_number_of_visits_to_a_interacted_agent <- nb_max_number_of_visits_to_a_interacted_agent;
	min_distance_to_exclude  <- nb_min_distance_to_exclude;
	}
	
	action increment_interactions_with_agent(agent interacted_agent){
		add interacted_agent::num_interactions_with_the_agent[interacted_agent] + 1 to:num_interactions_with_the_agent;
	}
	
	action add_interacted_target(point target){
		add target to: interacted_target;
	}
	
	action add_agents_interacted_within_cycle(pair<point, int> agents_cycle){
		add agents_cycle to: agents_interacted_within_cycle;
	}
	
	pair<agent, float> get_max_score(map<agent, float> agent_score){
		return agent_score.pairs with_max_of(each.value);
	}	
	
	action show_my_personality {
		write self.my_personality;
	}
	
	map<agent, float> get_distances(list<agent> agents_in_my_view){
		return map<agent, float>(agents_in_my_view collect (each::self distance_to (each)));
	}

	list remove_interacted_target(list list_of_points, int cycle){
		map<point, int> agents_within_limit ; 
		list<point> agents_to_remove;
		
		// We have a parameter to define the min cycles to consider before a Seller can return to an already visited Buyer
		agents_within_limit <- map<point, int>(agents_interacted_within_cycle.pairs where ((cycle - each.value) < number_of_cycles_to_return_interacted_agent));
		agents_to_remove <- agents_within_limit.keys;

		// We have a parameter to define the max number of visits to consider as a limit to a seller be able to visit again the same buyer
		agents_within_limit  <- map<point, int>(num_interactions_with_the_agent.pairs where ((each.value) >= max_number_of_visits_to_a_interacted_agent ));
		agents_to_remove <- (agents_to_remove union agents_within_limit.keys);
		
		remove all:agents_to_remove from: list_of_points;
		
		return list_of_points;
	}
	
	float get_normalized_values(float value, map<agent, float> agents_values, string criteria_type){
		if criteria_type="cost"{
			return value>0 ? abs(min(agents_values) / value) : 1.0;	
		} else {
			return value>0 ? abs(value / max(agents_values)) : 0.0;
		}
	}
	
	map<agent, float> get_agents_in_my_view(list<agent> list_of_agents){
		list_of_agents <- reverse (list_of_agents sort_by (each distance_to self));
		
		// Get the distance of each Buyer to the Seller and calculate the inverted norm score
		map<agent, float> agents_distance_to_me  <- get_distances(list_of_agents);
		map<agent, float> agents_distance_norm_global <- agents_distance_to_me.pairs as_map (each.key::(get_normalized_values(each.value, agents_distance_to_me, "cost")));
		
		return agents_distance_norm_global;
	}
	
	action calculate_score(list<agent> agents_in_my_view, int cycle){
 
		agents_in_my_view <- agents_in_my_view sort_by(each);
		agents_distance_norm_global <- get_agents_in_my_view(agents_in_my_view);
		
		// Calculate score for E-I 
		map<agent, float> agents_e_i_score;
		if (self.E_I contains_any ["E", "I"]) {agents_e_i_score <- get_extroversion_introversion_score(agents_in_my_view);}
		
		// Calculate score for S-N 
		map<agent, float> agents_s_n_score ;
		if (self.S_N contains_any ["S", "N"]) {agents_s_n_score <- get_sensing_intuition_score(agents_in_my_view);}
		
		// Calculate score for T-F
		// In T-F dichotomy we need to consider both, the target agents and our colleagues 
		map<agent, float> agents_t_f_score;
		if (self.T_F contains_any ["T", "F"]) {agents_t_f_score <- get_thinking_feeling_score(agents_in_my_view, colleagues_in_my_view);}
		
		// Sum all scores
		map<agent, float> agents_score;
		
		agents_score <- map<agent, float>(agents_in_my_view collect (each:: (agents_e_i_score[each]*weight_e_i) +
																					 (agents_s_n_score[each]*weight_s_n) +
																					 (agents_t_f_score[each]*weight_t_f)		
		));
		
		// We sort map to avoid diferent values between the simulations (when a tie happen on the scores) 
		agents_score <- agents_score.pairs collect (each.key::each.value) sort_by(each.key) sort_by(each.value);
		
		return agents_score;
	}
	
	map<agent, float> get_extroversion_introversion_score(list<agent> agents_to_calculate){
		
		map<agent, float> score_e_i;
		map<agent, float> num_interactions_with_the_agent_init <- map<agent, float>(agents_to_calculate collect (each:: 0.0));
		
		num_interactions_with_the_agent <- map<agent, float>((num_interactions_with_the_agent_init.keys - num_interactions_with_the_agent.keys) collect (each::num_interactions_with_the_agent_init[each]) 
									+ num_interactions_with_the_agent.pairs);

		// When there is a unique agent we can simply consider it as the max score
		if(length(agents_to_calculate)=1){
			score_e_i <-  map<agent, float>(agents_to_calculate collect (first(each)::1.0));
		}
		else {			
		
			map<agent, float> num_interactions_to_the_agent_norm;

			string criteria_type;

			// According to the seller personality type the normalization procedure will change (cost or benefit attribute) 
			criteria_type <- self.is_extroverted ? "cost" : "benefit";			 
			map<agent, float> num_interactions_with_the_agent_norm <- num_interactions_with_the_agent.pairs as_map (each.key::float(get_normalized_values(each.value, num_interactions_with_the_agent, criteria_type)));
			
			// Calculate SCORE-E-I
			score_e_i <- agents_distance_norm_global.pairs as_map (each.key::each.value+(num_interactions_with_the_agent_norm[each.key]));	
		}		
		
		return score_e_i;
	}
	
	map<agent, float> get_sensing_intuition_score (list<agent> agents_to_calculate){
		map<agent, float> score_s_n;

		// When there is a unique agent we can simply consider it as the max score
		if(length(agents_to_calculate)=1){
			score_s_n <-  map<agent, float>(agents_to_calculate collect (first(each)::1.0));
		}
		else {
		
			// Calculate the density using simple_clustering_by_distance technique
			list<list<agent>> clusters <- list<list<agent>>(simple_clustering_by_distance(agents_to_calculate, 10));
			
			list<map<list<agent>, int>> clusters_density <-list<map<list<agent>, int>>(clusters collect (each::length(each)));
			
			// We must navigate in three different levels because of the structure of the list of maps of lists		
			// Given that, we create a map of agents with the density of their own cluster
			map<agent, float> agents_density;
			loop cluster over:clusters_density{
				loop agents_by_density over: cluster.pairs{
					loop agent_unique over: agents_by_density.key {
						add agent_unique::agents_by_density.value to:agents_density;				
					}				
				}
			}
			
			float distance_weight;
			float density_weight;
			float agents_closest_to_edge_weight;
			
			density_weight <- self.is_sensing ? 0.1 : 0.25;
			agents_closest_to_edge_weight <- self.is_sensing ? 0.1 : 0.25;
			distance_weight <- 1 - density_weight - agents_closest_to_edge_weight; 			
			
			// Normalize density as a benefit attribute
			map<agent, float> agents_density_norm;
			agents_density_norm <- agents_density.pairs as_map (each.key::(max(agents_density)>1) ? get_normalized_values(each.value, agents_density, "benefit") : 1.0);
			
			// Calculate closest cluster point to the edge (perception radius)
			list<point> cluster_list;
			agent agent_closest_to_edge;
			map<agent, float> agents_closest_to_edge;
			
			loop cluster over: clusters{
				cluster_list <- list<point>((cluster collect each));
				agent_closest_to_edge <- agent_closest_to(geometry(cluster) farthest_point_to(point(self)));
				add agent_closest_to_edge ::(agent_closest_to_edge  distance_to self) to:agents_closest_to_edge;
			}
			
			// Normalize buyers_closest_to_edge as a benefit attribute
			map<agent, float> agents_closest_to_edge_norm;
			agents_closest_to_edge_norm <- agents_closest_to_edge.pairs as_map (each.key::get_normalized_values(each.value, agents_closest_to_edge, "benefit"));
			
			// Calculate SCORE-S-N
			score_s_n <- agents_distance_norm_global.pairs as_map (each.key::((each.value*distance_weight)
																			 +(agents_density_norm[each.key]*density_weight)
																			 +(agents_closest_to_edge_norm[each.key]*agents_closest_to_edge_weight)
			));
		
		}

		return score_s_n;		
	}
		
	map<agent, float> get_thinking_feeling_score(list<agent> agents_to_calculate, list<agent> my_colleagues){
		map<agent, float> score_t_f;
		
		float inc_num_agents_close_to_target_agent <- 0.0;
		map<agent, float> num_agents_close_to_target_agent;	
		
		// We sort the list to avoid diferent values between the simulations (when a tie happen on the scores)
		my_colleagues  <- my_colleagues sort_by(each);
		
		loop target_agent over: agents_to_calculate{ // targets
			loop agent_perceived over: my_colleagues{ // colleagues
				if(point(agent_perceived) distance_to point(target_agent) < min_distance_to_exclude){
					inc_num_agents_close_to_target_agent  <- inc_num_agents_close_to_target_agent + 1.0;	
				}
			}
			add target_agent::inc_num_agents_close_to_target_agent to:num_agents_close_to_target_agent;
			inc_num_agents_close_to_target_agent <- 0.0;
		}
	
		// We give more weight for feeling agents
		float agents_close_to_target_agent_weight;
		float distance_weight; 
		
		agents_close_to_target_agent_weight <- !self.is_thinking ? 0.8 : 0.2; 
		distance_weight <- 1 - agents_close_to_target_agent_weight ; 
		
		// Normalize num_agents_close_to_main_agent as a cost attribute and apply the weight
		map<agent, float> num_agents_close_to_target_agent_norm;
		num_agents_close_to_target_agent_norm <- num_agents_close_to_target_agent.pairs as_map (each.key::(get_normalized_values(each.value, num_agents_close_to_target_agent, "cost")));		
		
		// Calculate SCORE-T-F
		score_t_f <- agents_distance_norm_global.pairs as_map (each.key::((each.value*distance_weight)+(num_agents_close_to_target_agent_norm[each.key]*agents_close_to_target_agent_weight)));
		
		return score_t_f;		
	}
	
	point get_judging_perceiving(list<agent> agents_to_calculate, point current_target, int cycle){
		bool must_recalculate_plan;
		point new_target;
		
		// If is a perceiveing agent it has 80% probabability to recalcute the plan
		must_recalculate_plan <- !self.is_judging ? flip(0.8) : flip(0.2);
		
		if(must_recalculate_plan and self.J_P contains_any ["J", "P"]){
		
			map<agent, float> new_agents_score;
			new_agents_score <- calculate_score(agents_to_calculate, cycle);
						
			if (!empty(new_agents_score )) {
				map<agent, float> max_agent_score <- get_max_score(new_agents_score);
				new_target <- point(max_agent_score.keys[0]);	
			}
			return new_target;			
		}
		
		return current_target;
	}	

}

