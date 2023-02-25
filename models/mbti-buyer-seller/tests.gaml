/**
* Name: tests
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model tests

/* Insert your model definition here */

global {
	string teams_mbti_string_2;
	
	init {
		write teams_mbti_string_2;
	}
}

species My_Agent {
	
}

experiment tests type: gui keep_seed: true autorun: false{
	parameter "Teams MBTI" var: teams_mbti_string_2 init: "E,R,R,R";
}
