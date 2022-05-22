/**
* Name: TestsParameters
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model TestsParameters

global {
	int parameter1;
	
	init {
		write "parameter1:" +  parameter1;
	}
}
experiment Teste type: gui {
	parameter name: "parameter1" var: parameter1 init: 0;
}