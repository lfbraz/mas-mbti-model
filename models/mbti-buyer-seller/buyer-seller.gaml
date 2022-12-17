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

species Seller parent: Person {



}

experiment Simple type: gui{
	action _init_ {
		create simulation with: (			
			seed: 0
		);
	}
}