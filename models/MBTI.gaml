/**
* Name: MBTI1
* MBTI model 
* Author: Luiz Braz
* Tags: 
*/

model MBTI

global {
	int nbitem <- 10;
	int nbsellers <-3;
	int nbbuyers <-10;
	company the_company;
	geometry shape <- square(200);
	
	init {
		
		create company {
			the_company <- self;
		}
		create item number: nbitem;
		create buyers number: nbbuyers;

		create sellers number: nbsellers {
			do init(['I','S','T','J']);
		}		
		create sellers number: nbsellers {
			do init(['E','S','T','P']);
		}	
	}
	
	reflex stop when:length(item)=0{
		do pause;
	}
}

species sellers skills: [moving] control: simple_bdi{
	float viewdist <- 20.0;
	float speed <- 3.0 min:2.0 max: 100.0;
	int count_people_around <- 0 ;
	bool got_item <- false;
	bool got_buyer <- false;
	image_file my_icon <- image_file("../includes/seller.png");

	// MBTI
	string E_I;
	bool extroverted_prob;
	
	rgb color;
	
	//to simplify the writting of the agent behavior, we define as variables 4 desires for the agents
	predicate define_item_target <- new_predicate("define_item_target");
	predicate define_buyer_target <- new_predicate("define_buyer_target");
	predicate get_item <- new_predicate("get_item");
	predicate sell_item <- new_predicate("sell_item");
	predicate wander <- new_predicate("wander");
	predicate return_company <- new_predicate("return_company");
	
	predicate sac <- new_predicate("sac",["contenance"::5]);
	
	//we define in the same way a belief that I have already item that I have to return to the base
	predicate has_item <- new_predicate("has_item");

	predicate met_buyer <- new_predicate("met_buyer");
	
	point target;
	
	//at the creation of the agent, we add the desire to patrol (wander)
	action init (list<string> mbti)
	{
		
		E_I <- mbti at 0; // E (extroverted) or I (introverted)
		color <- (E_I='E') ? #orange : #green;	

		do add_desire(wander);
	}
	
	
	float get_speed(string personality, int qty_agents){
				
		// When an agent is E it has 80% probability to be extroverted. 
		extroverted_prob <- personality='E' ? flip(0.8) : flip(0.2);
		
		// An extroverted agent increase speed with more agents around.
		if(extroverted_prob){
			switch count_people_around {
				match 0 {
					speed <- speed  - (speed * 0.8);
				}
				match_between [1,3]{
					speed <- speed  + (speed * 0.2);
				}
				match_between [3,5]{
					speed <- speed  + (speed * 0.4);
				}
				match_between [5,8]{
					speed <- speed  + (speed * 0.6);
				}
				match_between [8,-#infinity]{
					speed <- speed  + (speed * 0.8);
				}
			}
		}
		// For an introverted agent is the opposite, your speed will be decreased.
		else{
			switch count_people_around {
				match 0 {
					speed <- speed  + (speed * 0.8);
				}
				match_between [1,3]{
					speed <- speed  - (speed * 0.2);
				}
				match_between [3,5]{
					speed <- speed  - (speed * 0.4);
				}
				match_between [5,8]{
					speed <- speed  - (speed * 0.6);
				}
				match_between [8,-#infinity]{
					speed <- speed  - (speed * 0.8);
				}
			}			
		}				
		
		return speed;
	}
	
	//if the agent perceive a item in its neighborhood, it adds a belief concerning its location and remove its wandering intention
	perceive target:item in:viewdist {
		focus id:"location_item" var:location;
		ask myself {do remove_intention(wander, false);}
	}
	
	reflex count_people_around_me{
		count_people_around <- length(self neighbors_at(viewdist*2));
		speed <- get_speed(E_I, count_people_around);

		write "Probabilidade Extrovertido: " + extroverted_prob;
		write "Velocidade: " + speed;		
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
			do goto target: target;
						
			//if the agent reach its location, it updates it takes the item, updates its belief base, and remove its intention to get item
			if (target = location)  {
				got_buyer <- true;

				buyers current_buyer <- buyers first_with (target = each.location);
				if current_buyer != nil {
					do add_belief(met_buyer);			 	
				}
				
				do remove_belief(new_predicate("location_buyer", ["location_value"::target]));
				target <- nil;				
				do remove_intention(sell_item, true);
				
			}
		}
	}

	//plan that has for goal to fulfill the define item target desire. This plan is instantaneous (does not take a complete simulation step to apply).
	plan choose_buyer_target intention: define_buyer_target instantaneous: true{
		list<point> possible_buyers <- get_beliefs(new_predicate("location_buyer")) collect (point(get_predicate(mental_state (each)).values["location_value"]));

		if (empty(possible_buyers)) {
			do remove_intention(wander, true);
		} else {
			target <- (possible_buyers with_min_of (each distance_to self)).location;
		}
		do remove_intention(define_buyer_target, true);
	}
	
	//plan that has for goal to fulfill the get item desire
	plan getItem intention:get_item
	{
		//if the agent does not have chosen a target location, it adds the sub-intention to define a target and puts its current intention on hold
		if (target = nil) {
			do add_subintention(get_current_intention(), define_item_target, true);
			do current_intention_on_hold();
		} else {
			do goto target: target;
						
			//if the agent reach its location, it updates it takes the item, updates its belief base, and remove its intention to get item
			if (target = location)  {
				got_item <- true;

				item current_item <- item first_with (target = each.location);
				if current_item != nil {
					do add_belief(has_item);			 	
					ask current_item {do die;}
				}
				
				do remove_belief(new_predicate("location_item", ["location_value"::target]));
				target <- nil;				
				do remove_intention(get_item, true);
				
			}
		}	
	}
	
	//plan that has for goal to fulfill the define item target desire. This plan is instantaneous (does not take a complete simulation step to apply).
	plan choose_item_target intention: define_item_target instantaneous: true{
		list<point> possible_itens <- get_beliefs(new_predicate("location_item")) collect (point(get_predicate(mental_state (each)).values["location_value"]));

		if (empty(possible_itens)) {
			do remove_intention(get_item, true);
		} else {
			target <- (possible_itens with_min_of (each distance_to self)).location;
		}
		do remove_intention(define_item_target, true);
	}
	
	//plan that has for goal to fulfill the return to base desire
	plan return_to_company intention: return_company{
		write "Localização agente:" + location;
		sellers current_people <- sellers first_with (location = location);
		
		do goto target: the_company ;
		if (the_company.location = location)  {
			got_item <- false;			
			do remove_belief(has_item);
			do remove_intention(return_company, true);
			the_company.itens <- the_company.itens + 1;
		}
	}
	
	aspect default {	  
	  	
	  draw circle(3) color: color;
	  // draw my_icon size: 5;
	  draw triangle(1) color: (got_item) ? #yellow : color;
	  
	  // enable view distance
	  // draw circle(viewdist) color:rgb(#white,0.5) border: #red;

	  draw ("MBTI:" + E_I) color:#black size:4;
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
		do add_desire(wander);
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

species item {	
	aspect default {
		draw triangle(0.5) color: #yellow border: #black;
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
			species item;			
		}		
	}
}

