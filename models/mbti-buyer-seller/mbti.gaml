/**
* Name: mbti
* Based on the internal empty template. 
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
	int number_of_cycles_to_return_interacted_agent <- 5;
	int max_number_of_visits_to_a_interacted_agent <- 3;
	
	list my_personality;
	
	bool is_extroverted;
	bool is_sensing; 
	bool is_thinking;
	bool is_judging;	
	
	map<agent, float> num_interactions_with_the_agent;
	map<point, float> agent_distance_norm_global;
	list<point> interacted_target;
	map<point, int> agents_interacted_within_cycle;
	map<agent, float> agents_distance_norm_global;
	
	list set_my_personality(list<string> mbti_personality,
							bool use_probability
	){
		// Check if the MBTI should be randomized
		if(mbti_personality contains "R"){
			mbti_personality <- randomize_personality(mbti_personality);
		}
		
		string E_I <- mbti_personality at 0;
		string S_N <- mbti_personality at 1;
		string T_F <- mbti_personality at 2;
		string J_P <- mbti_personality at 3;
		
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

	list get_agents_from_points(list list_of_points){
		list<agent> list_of_agents; 
		loop agent_unique over: list_of_points{
			add agent_closest_to(agent_unique) to: list_of_agents;
		}
		return list_of_agents;	
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
	
	action calculate_score(list<point> agents_to_calculate, int cycle){
		
		// Remove target according to the model constraints
		agents_to_calculate <- remove_interacted_target(agents_to_calculate, cycle);
		
		list<agent> agents_in_my_view;
		agents_in_my_view <- get_agents_from_points(agents_to_calculate);
		
		agents_distance_norm_global <- get_agents_in_my_view(agents_in_my_view);
		
		// Calculate score for E-I 
		map<agent, float> agents_e_i_score;
		if (self.my_personality contains_any ["E", "I"]) {agents_e_i_score <- get_extroversion_introversion_score(agents_in_my_view);}
		
		// Calculate score for S-N 
		//map<agent, float> agents_s_n_score ;
		//if (self.my_personality contains_any ["S", "N"]) {agents_s_n_score <- get_sensing_intuition_score(agents_to_calculate);}
		
		// Sum all scores
		map<agent, float> agents_score;
		
		agents_score <- map<agent, float>(agents_in_my_view collect (each:: (agents_e_i_score[each]*weight_e_i) //+
																					 //(agents_s_n_score[each]*weight_s_n) 		
		));
		
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
				// Given that, we create a map of Buyers with the density of their own cluster
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
					agent_closest_to_edge <- agent(geometry(cluster) farthest_point_to(point(self)));
					add agent_closest_to_edge ::(agent_closest_to_edge  distance_to self) to:agents_closest_to_edge;
				}
				
				// Normalize buyers_closest_to_edge as a benefit attribute
				map<agent, float> agents_closest_to_edge_norm;
				agents_closest_to_edge_norm <- agents_closest_to_edge_norm.pairs as_map (each.key::get_normalized_values(each.value, agents_closest_to_edge, "benefit"));
				
				// Calculate SCORE-S-N
				score_s_n <- agents_distance_norm_global.pairs as_map (each.key::((each.value*distance_weight)
																				 +(agents_density_norm[each.key]*density_weight)
																				 +(agents_closest_to_edge_norm[each.key]*agents_closest_to_edge_weight)
				));
			
			}
	
			return score_s_n;		
		}
	
}
