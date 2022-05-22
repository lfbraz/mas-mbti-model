/**
* Name: GenerateRandom
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model GenerateRandom

global {
	list<string> teams_mbti <- ['R','R','R','R'];
	init {
		create random number: 10;
	}
}

species random {

list<string> mbti_personality;

init {
	write "teams_mbti: " + teams_mbti;
	list<string> my_copy <- copy(teams_mbti);
	mbti_personality <- randomize_personality(my_copy);
	write mbti_personality;
}

list<string> randomize_personality (list<string> my_mbti_personality) {
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

}

experiment Attributes type: gui {
	float seed <- 1985.0;

}