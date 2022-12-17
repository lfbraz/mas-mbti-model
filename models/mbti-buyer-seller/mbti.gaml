/**
* Name: mbti
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model mbti


species Person skills: [moving]{
	list my_personality;
	
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
		bool is_extroverted;
		bool is_sensing; 
		bool is_thinking;
		bool is_judging;		
		
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
	
	action show_my_personality {
		write self.my_personality;
	}
}
