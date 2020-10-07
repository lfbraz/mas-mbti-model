/**
* Name: MBTI1
* MBTI model 
* Author: Luiz Braz
* Tags: 
*/

model MBTI

global {

	int nbitem <- 10;
	int nbsellers <-1;
	int nbbuyers <-15;
	
	int steps <- 0;
	int max_steps <- 100;
	
	geometry shape <- square(400);
	
	init {
		
		create buyers number: nbbuyers;

		create sellers number: nbsellers {
			do init(['I','N','T','J']);
		}		
		
		//create sellers number: nbsellers {
		//	do init(['E','S','T','P']);
		//}	
	}
	
	reflex stop when:steps=100{
		do pause;
	}
	
	reflex count{
		steps  <- steps + 1;
		write "step:" + steps;
	}
}

species sellers skills: [moving] control: simple_bdi{
	float viewdist_coworkers <- 10.0;
	float viewdist_buyers <- 30.0;
	float speed <- 3.0 min:2.0 max: 100.0;
	int count_people_around <- 0 ;
	bool got_buyer <- false;
	//image_file my_icon <- image_file("../includes/seller.png");

	// MBTI
	string E_I;
	bool extroverted_prob;
	
	string S_N;
	bool sensing_prob;

	string J_P;
	bool judging_prob;

	bool already_visited_cluster <- false;
	
	rgb color;
	
	//to simplify the writting of the agent behavior, we define as variables 4 desires for the agents
	predicate define_item_target <- new_predicate("define_item_target");
	predicate define_buyer_target <- new_predicate("define_buyer_target");
	predicate sell_item <- new_predicate("sell_item");
	predicate wander <- new_predicate("wander");
	predicate met_buyer <- new_predicate("met_buyer");
	
	point target;
	list<point> visited_target;
	list<point> perceived_buyers;
	
	//at the creation of the agent, we add the desire to patrol (wander)
	action init (list<string> mbti)
	{		
		// E (extroverted) or I (introverted)
		E_I <- mbti at 0; 
		color <- (E_I='E') ? #orange : #green;	
		
		// S (sensing) or N (iNtuiton)
		S_N <- mbti at 1; 
		// When an agent is S it has 80% probability to be sensing. 
		sensing_prob <- S_N='S' ? flip(0.8) : flip(0.2);
		color <- (S_N='S') ? #yellow : #red;
		
		// J (judging) or P (perceiving)
		J_P <- mbti at 2; 
		// When an agent is S it has 80% probability to be sensing. 
		judging_prob <- J_P='J' ? flip(0.8) : flip(0.2);
		color <- (J_P='S') ? #purple : #gray;
		
		// All the agents must know the existing clusters
		//do get_biggest_cluster();
		
		// Begin to wander
		do add_desire(wander);
	}
	
	
	float get_speed(string personality, int qty_agents){
				
		// When an agent is E it has 80% probability to be extroverted. 
		extroverted_prob <- personality='E' ? flip(0.8) : flip(0.2);
		
		// An extroverted agent increase speed with more agents around.
		if(extroverted_prob){
			switch count_people_around {
				match 0 {
					speed <- speed  - (speed * 0.3);
				}
				match_between [1,3]{
					speed <- speed  + (speed * 0.2);
				}
				match_between [3,5]{
					speed <- speed  + (speed * 0.25);
				}
				match_between [5,8]{
					speed <- speed  + (speed * 0.28);
				}
				match_between [8,-#infinity]{
					speed <- speed  + (speed * 0.3);
				}
			}
		}
		// For an introverted agent is the opposite, your speed will be decreased.
		else{
			switch count_people_around {
				match 0 {
					speed <- speed  + (speed * 0.3);
				}
				match_between [1,3]{
					speed <- speed  - (speed * 0.2);
				}
				match_between [3,5]{
					speed <- speed  - (speed * 0.25);
				}
				match_between [5,8]{
					speed <- speed  - (speed * 0.28);
				}
				match_between [8,-#infinity]{
					speed <- speed  - (speed * 0.3);
				}
			}			
		}				
		
		return speed;
	}
	
	
	
	//if the agent perceive a buyer in its neighborhood, it adds a belief concerning its location and remove its wandering intention
	perceive target:buyers in: viewdist_buyers*2{
		focus id:"location_buyer" var:location;		
		ask myself {do remove_intention(wander, false);	}
	}
	
	list get_biggest_cluster(list possible_buyers){	  	
	  	list<list<buyers>> clusters <- list<list<buyers>>(simple_clustering_by_distance(possible_buyers, 30));
	  	// Alter the colors to check if everything is OK
	  	//loop cluster over: clusters {
	  	//   write cluster;
	  	//   rgb rnd_color <- rgb(rnd(255),rnd(255),rnd(255));
	  	//   ask cluster as: buyers {color <- rnd_color;}               		
        //}	 
	  	return clusters with_max_of(length(each));	  	 	
	  }
	  
	list get_buyers_from_points(list list_of_points){
		list<buyers> list_of_buyers; 
		loop buyer over: list_of_points{
			add buyers(buyer) to: list_of_buyers;
		}
		return list_of_buyers;	
	}		
	  
	reflex count_people_around_me{
		write "LISTA DE PERCEIVED" + perceived_buyers;
		count_people_around <- length(self neighbors_at(viewdist_coworkers));
		speed <- get_speed(E_I, count_people_around);	
		}
	
	//if the agent has the belief that there is a possible buyer given location, it adds the desire to interact with the buyer to try to sell items.
	rule belief: new_predicate("location_buyer") new_desire: sell_item strength:10.0;

	// plan that has for goal to fulfill the wander desire	
	plan letsWander intention:wander 
	{
		do wander amplitude: 60.0 speed: speed;
	}
	
	// plan that has for goal to fulfill the "sell_item" desire
	plan sellItem intention:sell_item{
		//if the agent does not have chosen a target location, it adds the sub-intention to define a target and puts its current intention on hold
		if (target = nil) {
			do add_subintention(get_current_intention(), define_buyer_target, true);
			do current_intention_on_hold();
		} else {
			
			if(judging_prob){
				do goto target: target;				
			}else {
				do goto target: target;
			}
			
			write self.name + " INDO PRO TARGET";
		
			//if the agent reach its location, it updates it takes the item, updates its belief base, and remove its intention to get item
			if (target = location)  {
				got_buyer <- true;
				
				buyers current_buyer <- buyers first_with (target = each.location);
				if current_buyer != nil {
					do add_belief(met_buyer);			 	
				}
				
				do remove_belief(new_predicate("location_buyer", ["location_value"::target]));
				add target to: visited_target;
				
				target <- nil;				
				do remove_intention(sell_item, true);
			}
		}
	}
	
		
	//plan that has for goal to fulfill the define item target desire. This plan is instantaneous (does not take a complete simulation step to apply).
	plan choose_buyer_target intention: define_buyer_target instantaneous: true{
		list<point> possible_buyers <- get_beliefs(new_predicate("location_buyer")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		
		write 'ANTES REMOÇÃO: possible_buyers:' + possible_buyers + ' - agent:' + self.name;
		remove all:visited_target from: possible_buyers;
		write 'DEPOIS REMOÇÃO: possible_buyers:' + possible_buyers + ' - agent:' + self.name;
		
		if (empty(possible_buyers)) {
			do remove_intention(sell_item, true);
			do remove_intention(define_buyer_target, true);
			do add_desire(wander);
			write "ADICIONEI O DESEJO wander";
		} else {
		
			write "TESTANDO A CLUSTERIZAÇÃO POR possible_buyers";
			write "LISTA DE possible_buyers:" + possible_buyers;
			list<buyers> list_of_buyers <- get_buyers_from_points(possible_buyers);
			write "LISTA DE list_of_buyers :" + list_of_buyers;
			
			// S agents focus on short-term (min distance to target) and  
			// N agents focus on "big-picture" and long-term gains (density is more important)
			list cluster <- get_biggest_cluster(list_of_buyers);
			write("MAIOR CLUSTER ENCONTRADO:" + cluster);
			
			if(sensing_prob or already_visited_cluster) {
				target <- (possible_buyers with_min_of (each distance_to self)).location;
			} else {
				target <- cluster with_min_of (point(each) distance_to self);
				already_visited_cluster <- true;				
			}
			
		}
		do remove_intention(define_buyer_target, true);
	}
	
	aspect default {	  
	  	
	  draw circle(3) color: color;
	  // draw my_icon size: 5;
	  
	  // enable view distance
	  draw circle(viewdist_buyers*2) color:rgb(#white,0.5) border: #red;

	  draw ("MBTI:" + E_I + "(" + extroverted_prob + ")" + S_N + sensing_prob + ")") color:#black size:4;
	  draw ("Agentes ao redor:" + count_people_around) color:#black size:4 at:{location.x,location.y+4};
	  draw ("Velocidade:" + speed) color:#black size:4 at:{location.x,location.y+2*4}; 
	  
	  //write("Intenção Corrente:" + get_values(has_item)  ) ;
	   
	  //draw ("B:" + length(belief_base) + ":" + belief_base) color:#black size:4; 
	  //draw ("D:" + length(desire_base) + ":" + desire_base) color:#black size:4 at:{location.x,location.y+4}; 
	  //draw ("I:" + length(intention_base) + ":" + intention_base) color:#black size:4 at:{location.x,location.y+2*4}; 
	  //draw ("curIntention:" + get_current_intention()) color:#black size:4 at:{location.x,location.y+3*4};
	  //draw ("possible_itens:" + get_current_intention()) color:#black size:4 at:{location.x,location.y+4*4}; 		
	}
}


species buyers skills: [moving] control: simple_bdi {	
	rgb color <- #blue;
	float speed <- 3.0;
	
	predicate wander <- new_predicate("wander");
	
	//at the creation of the agent, we add the desire to patrol (wander)
	init
	{		
		// do add_desire(wander);
	}
	
	// plan that has for goal to fulfill the wander desire	
	plan letsWander intention:wander 
	{
		do wander amplitude: 60.0 speed: speed;
	}
	
	aspect default {  
	  draw circle(3) color: color;
	}
}

species company {
	int itens;
	aspect default
	{
	  draw square(20) color: #blue;
	}
}

grid grille width: 40 height: 40 neighbors:4 {
	rgb color <- #white;
}

experiment MBTI type: gui {
	float minimum_cycle_duration <- 0.05;
	/** Insert here the definition of the input and output of the model */
	output {
		display map {
			grid grille lines: #darkgreen;
			species company;			
			species sellers aspect:default;
			species buyers aspect:default;
		}		
	}
}

