/**
* Name: mbti
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model mbti


species Person skills: [moving]{
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
	
	action add_interactions_with_agent(agent interacted_agent){
		add interacted_agent::num_interactions_with_the_agent[interacted_agent] + 1 to:num_interactions_with_the_agent;
	}
	
	action add_interacted_target(point target){
		add target to: interacted_target;
	}
	
	action add_agents_interacted_within_cycle(pair<point, int> agents_step){
		add agents_step to: agents_interacted_within_cycle;
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
	
	float get_normalized_values(float value, map<agent, float> agents_values, string criteria_type){
		if criteria_type="cost"{
			return value>0 ? abs(min(agents_values) / value) : 1.0;	
		} else {
			return value>0 ? abs(value / max(agents_values)) : 0.0;
		}
	}
	
	map<agent, float> get_agents_in_my_view(list<agent> list_of_agents){
		list_of_agents <- reverse (list_of_agents sort_by (each distance_to self));
		
		// Get the distance of each buyer to the seller and calculate the inverted norm score
		map<agent, float> agents_distance_to_me  <- get_distances(list_of_agents);
		map<agent, float> agents_distance_norm_global <- agents_distance_to_me.pairs as_map (each.key::(get_normalized_values(each.value, agents_distance_to_me, "cost")));
		
		return agents_distance_norm_global;
	}
	
	action calculate_score(list<agent> buyers_to_calculate){
		
		agents_distance_norm_global <- get_agents_in_my_view(buyers_to_calculate);
		write "agents_distance_norm_global: " + agents_distance_norm_global;
		
		// Calculate score for E-I 
		map<agent, float> buyers_e_i_score;
		if (self.my_personality contains_any ["E", "I"]) {buyers_e_i_score <- get_extroversion_introversion_score(buyers_to_calculate);}		
	}
	
	map<agent, float> get_extroversion_introversion_score(list<agent> agents_to_calculate){
		map<agent, float> score_e_i;

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
	
}
