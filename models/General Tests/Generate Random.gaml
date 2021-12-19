/**
* Name: GenerateRandom
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model GenerateRandom

species random {

list<string> mbti_personality;

init {
	mbti_personality <- ['E','R','R','R'];
	
	do randomize_personality(mbti_personality);	
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
}

}

experiment Attributes type: gui {
	user_command "Generating Random" {create random;}
}