/**
* Name: buyer_seller
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model buyer_seller
import "mbti.gaml"

global {
	init {
		create Seller {
			write "Seller with prob";
			do set_my_personality(["I", "S", "T", "J"], true); // Using probability
			do show_my_personality();
		}
		
		create Seller {
			write "Seller without prob";
			do set_my_personality(["I", "S", "T", "J"], false); // Not using probability
			do show_my_personality();
		}
		
		create Seller {
			write "Seller Random";
			do set_my_personality(["R", "R", "R", "R"], false); // Not using probability
			do show_my_personality();
		}
	}
}

species Seller parent: Person control: simple_bdi{

	// Define agent behavior
	predicate wander <- new_predicate("wander");
	
	init{
		// Begin to wander
		do add_desire(wander);
	}
	
	// plan that has for goal to fulfill the wander desire	
	plan letsWander intention:wander 
	{
		do wander amplitude: 60.0;
	}
	
	aspect default {
		image_file buyer_icon <- image_file("../../includes/seller.png");	
		draw buyer_icon size: 4; 	
	}
}

grid grille_low width: 10 height: 10 {
	rgb color <- #white;
}

experiment Simple type: gui{
	action _init_ {
		create simulation with: (			
			seed: 0
		);
	}
	
	output {
		display map {
			grid grille_low lines: #gray;
			species Seller aspect:default;
		}
	}
}