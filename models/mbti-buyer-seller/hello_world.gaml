/**
* Name: helloworld
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model helloworld

/* Insert your model definition here */
global {
	init {
		write "Hello World";	
	}		
}

species sellers {
	init {
		write "create seller";
	}
	
	reflex count {
		write "aqui";
	}
	aspect default {
		 draw square(2) color: #purple;
	}
}

species buyers {
	rgb color <- #green;	
	aspect default {  	 
	  draw triangle(3) color:#red;
	}
}

grid grille_low width: 10 height: 10 {
	rgb color <- #white;
}

experiment test type: gui {
	init {
		write "Experiment Hello World";	
		create buyers number: 10;
		create sellers number: 2;
	}
	
	output {
		display map {
			grid grille_low lines: #gray;
			species sellers aspect:default;
			species buyers aspect:default;
		}
	}
	
}