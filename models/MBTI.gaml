/**
* Name: MBTI1
* MBTI model 
* Author: Luiz Braz
* Tags: 
*/

model MBTI

global {

	int nbitem <- 10;
	int nbsellers <-2;
	int nbbuyers <-50;
	
	int steps <- 0;
	int max_steps <- 1000;
	
	geometry shape <- square(500);
	map<string, string> PARAMS <- ['dbtype'::'sqlite', 'database'::'../db/mas-mbti-recruitment.db'];
	
	init {
		create buyers number: nbbuyers;

		create sellers number: nbsellers {
			do init(['I','N','T','J']);
		}		
		
		create sellers number: nbsellers {
			do init(['E','S','T','P']);
		}	
	}
	
	reflex stop when:steps=max_steps{
		do pause;
	}
	
	reflex count{
		steps  <- steps + 1;
		// write "step:" + steps;
	}
}

species sellers skills: [moving, SQLSKILL] control: simple_bdi{
	float viewdist_sellers <- 100.0;
	float viewdist_buyers <- 50.0;
	float speed <- 1.0;
	int count_people_around <- 0 ;
	bool got_buyer <- false;

	// MBTI
	string my_personality;
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
	predicate say_something <- new_predicate("say_something");
	predicate wander <- new_predicate("wander");
	predicate met_buyer <- new_predicate("met_buyer");
	
	point target;
	list<point> visited_target;
	list<point> perceived_buyers;
	
	list<point> sellers_in_my_view;
	
	int weight_qty_buyers <- 100;
	float min_distance_to_exclude <- 50.0;
	
	//at the creation of the agent, we add the desire to patrol (wander)
	action init (list<string> mbti_personality)
	{		
		
		// clean table
		do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_SCORE_E_I";
		do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_SCORE_S_N";
		do executeUpdate params: PARAMS updateComm: "DELETE FROM TB_TARGET";
		
		// MBTI
		my_personality <- string(mbti_personality);
		
		// E (extroverted) or I (introverted)
		E_I <- mbti_personality at 0; 
		extroverted_prob <- E_I = 'E' ? flip(0.8) : flip(0.2);
		color <- extroverted_prob ? #blue:#red;
		write "agent personality:" + E_I + " and extroverted_prob:" + extroverted_prob;
		
		// S (sensing) or N (iNtuiton)
		S_N <- mbti_personality at 1; 
		sensing_prob <- S_N=  'S' ? flip(0.8) : flip(0.2);
		
		// J (judging) or P (perceiving)
		J_P <- mbti_personality at 2; 
		judging_prob <- J_P = 'J' ? flip(0.8) : flip(0.2);
		
		// Begin to wander
		do add_desire(wander);
	}
	
	//if the agent perceive a buyer in its neighborhood, it adds a belief concerning its location and remove its wandering intention
	perceive target:buyers in: viewdist_buyers*2{
		focus id:"location_buyer" var:location;		
		ask myself {do remove_intention(wander, false);	}
	}
	
		//if the agent perceive a buyer in its neighborhood, it adds a belief concerning its location and remove its wandering intention
	perceive target:sellers in: viewdist_sellers*2{
		focus id:"location_seller" var:location;
		sellers_in_my_view <- get_beliefs(new_predicate("location_seller")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		do remove_belief(new_predicate("location_seller"));
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
	
	list get_sellers_from_points(list list_of_points){
		list<sellers> list_of_sellers; 
		loop seller over: list_of_points{
			add sellers(seller) to: list_of_sellers;
		}
		return list_of_sellers;	
	}
	
	list remove_visited_target(list list_of_points){
		remove all:visited_target from: list_of_points;
		return list_of_points;
	}
	
	action get_extroversion_introversion_score(list list_of_points){
		list<buyers> buyers_in_my_view <- get_buyers_from_points(list_of_points);
		buyers_in_my_view <- reverse (buyers_in_my_view sort_by (each distance_to self));
		
		//write self distance_to buyers(buyers_in_my_view);
		int rank <- 1;
		map<buyers, float> agents_score;
		
		loop buyer over: buyers_in_my_view {
			float score;
			float distance_buyer_to_me <- self distance_to buyers(buyer);			
			
			if(!self.extroverted_prob){
				score <- (distance_buyer_to_me * rank) - (buyers(buyer).qty_buyers * weight_qty_buyers);
			}else {
				score <- (distance_buyer_to_me * rank) * buyers(buyer).qty_buyers;
			}
			
			// Map agents and scores
			add buyers(buyer)::score to: agents_score;
			
			// log into db the calculated score
			do insert (params: PARAMS,
							into: "TB_SCORE_E_I",
							columns: ["INTERACTION", "SELLER_NAME", "MBTI_SELLER", "RANK", "DISTANCE_TO_BUYER", "NUMBER_OF_PEOPLE_AT_BUYER", "BUYER_NAME", "SCORE"],
							values:  [steps, self.name, self.my_personality, rank, distance_buyer_to_me, buyers(buyer).qty_buyers, buyers(buyer).name, score]);
							
			rank <- rank + 1;
		}
		
		write 'get_score_introversion_extroversion:' + self.name + " - " + agents_score;
		//map<buyers, float> best_score <- map<buyers, float>(agents_score.pairs with_max_of(each.value));
		map<buyers, float> buyers_score <- map<buyers, float>(agents_score.pairs);
		
		return buyers_score;
	}
	
	action get_sensing_intuition_score(list list_of_points, map<buyers, float> buyers_score_e_i){
		list<buyers> list_of_buyers <- get_buyers_from_points(list_of_points);
		list<list<buyers>> clusters <- list<list<buyers>>(simple_clustering_by_distance(list_of_buyers, 30));
		
		map<buyers, float> buyers_score;
		
		// For each cluster we update the score		
		loop cluster over:clusters{
			loop buyer over:cluster{
				map<buyers, float> buyer_score <- map<buyers, float>(buyers_score_e_i.pairs where (each.key = buyer) at 0);

				float score <- buyer_score.values[0] * length(cluster);
				
				// log into db the calculated score
				do insert (params: PARAMS,
							into: "TB_SCORE_S_N",
							columns: ["INTERACTION", "SELLER_NAME", "MBTI_SELLER", "CLUSTER_DENSITY", "CLUSTER", "BUYER_NAME", "SCORE"],
							values:  [steps, self.name, self.my_personality, length(cluster), string(cluster), buyers(buyer).name, score]);							
				
				add buyers(buyer)::score to:buyers_score;
			}			
		}		
		return buyers_score;		
	}
	
	action get_thinking_feeling_score(list list_of_points, map<buyers, float> buyers_score_t_f){
		list sellers_perceived <- get_sellers_from_points(sellers_in_my_view);
	
		loop seller over: sellers_perceived{
			loop buyer over: buyers_score_t_f.pairs{
				
				// if the buyers is in a minimal distance to the colleages we exclude it
				// TODO: consider teamates
				if(point(seller) distance_to point(buyer.key) < min_distance_to_exclude){
					remove all: buyer from: buyers_score_t_f;	
				}
			}
		}
		
		return buyers_score_t_f;		
	}
	  
	//if the agent has the belief that there is a possible buyer given location, it adds the desire to interact with the buyer to try to sell items.
	rule belief: new_predicate("location_buyer") new_desire: sell_item strength:10.0;

	//if the agent has the belief that there is a possible buyer given location, it adds the desire to interact with the buyer to try to sell items.
	//rule belief: new_predicate("location_seller") new_desire: say_something strength:10.0;


	// plan that has for goal to fulfill the wander desire	
	plan letsWander intention:wander 
	{
		do wander amplitude: 60.0 speed: speed;
	}
	
	//plan saySomething intention: say_something{
	//	write "Say Something";
	//} 
	
	// plan that has for goal to fulfill the "sell_item" desire
	plan sellItem intention:sell_item{
		//if the agent does not have chosen a target location, it adds the sub-intention to define a target and puts its current intention on hold
		if (target = nil) {
			do add_subintention(get_current_intention(), define_buyer_target, true);
			do current_intention_on_hold();
		} else {
			
			do goto target: target;
			
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

	action get_max_score(map<buyers, float> buyer_score){
		return buyer_score.pairs with_max_of(each.value);
	}
		
	//plan that has for goal to fulfill the define item target desire. This plan is instantaneous (does not take a complete simulation step to apply).
	plan choose_buyer_target intention: define_buyer_target instantaneous: true{
		list<point> possible_buyers <- get_beliefs(new_predicate("location_buyer")) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		
		possible_buyers <- remove_visited_target(possible_buyers);
		map<buyers, float> buyers_score;
		buyers_score <- get_extroversion_introversion_score(possible_buyers);
		
		// Calculate score for intuition agents
		if(!sensing_prob){
			buyers_score <- get_sensing_intuition_score(possible_buyers, buyers_score);
		}
		
		buyers_score <- get_thinking_feeling_score(possible_buyers, buyers_score);
						
		if (empty(possible_buyers)) {
			do remove_intention(sell_item, true);
			do remove_intention(define_buyer_target, true);
			do add_desire(wander);
		} else {
		
			map<buyers, float> max_buyer_score <- get_max_score(buyers_score);
			target <- point(max_buyer_score.keys[0]);
			
			// log into db the calculated score
			do insert (params: PARAMS,
						into: "TB_TARGET",
						columns: ["INTERACTION", "SELLER_NAME", "MBTI_SELLER", "BUYER_TARGET", "SCORE"],
						values:  [steps, self.name, self.my_personality, max_buyer_score.keys[0], max_buyer_score.values[0]]);
						
			if(!already_visited_cluster) {
				already_visited_cluster <- true;
			} 			
		}
		do remove_intention(define_buyer_target, true);
	}
	
	aspect default {	  
	  	
	  draw circle(18) color: color;
	  
	  // enable view distance
	  draw circle(viewdist_buyers*2) color:rgb(#white,0.5) border: #red;

	  if(extroverted_prob){
	  	draw ("MBTI:E" ) color:#black size:4;
	  } else{
	  	draw ("MBTI:I" ) color:#black size:4;
	  }

	  //draw ("Agentes ao redor:" + count_people_around) color:#black size:4 at:{location.x,location.y+4};
	  //draw ("Velocidade:" + speed) color:#black size:4 at:{location.x,location.y+2*4}; 
	  
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
	int qty_buyers <- rnd (1, 30);
	
	image_file buyer_icon <- image_file("../includes/buyer.png");
	
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
	  draw rectangle(30, 15) color: #orange at:{location.x,location.y-20};
	  draw (string(self.name)) color:#black size:4 at:{location.x-10,location.y-18};
	  draw circle(5) color: #green at:{location.x,location.y+20};
	  draw (string(self.qty_buyers)) color:#white size:4 at:{location.x-3,location.y+22}; 
	  draw buyer_icon size: 40;
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
			species sellers aspect:default;
			species buyers aspect:default;
		}		
	}
}

