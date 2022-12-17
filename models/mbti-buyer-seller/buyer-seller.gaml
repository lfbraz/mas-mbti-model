/**
* Name: buyer_seller
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/


model buyer_seller
import "mbti.gaml"

global {
	
	int nb_buyers <- 10;
	int nb_items_to_buy;

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
		
		create Buyer number: nb_buyers;
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

species Buyer skills: [moving] {
	rgb color <- #green;
	bool visited <- false;
	int current_demand;
	
	init{
		current_demand <- copy(nb_items_to_buy);
	}
	
	aspect default {
		draw triangle(3) color: current_demand=0? #red : color at:{location.x,location.y};		
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
			species Buyer aspect:default;
		}
	}
}