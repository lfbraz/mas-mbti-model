/**
* Name: MBTI1
* MBTI model 
* Author: Luiz Braz
* Tags: 
*/

model MBTI

global {
	int nbitem<-20;
	int nbpeople<-5;
	company the_company;
	geometry shape <- square(200);
	
	init {
		
		create company {
			the_company <- self;
		}
		create item number: nbitem;
		create people number: nbpeople;			
	}
	
	reflex stop when:length(item)=0{
		do pause;
	}
}

species people skills: [moving] control: simple_bdi{
	float viewdist <- 20.0;
	float speed <- 3.0;	
	
	//to simplify the writting of the agent behavior, we define as variables 4 desires for the agents
	predicate define_item_target <- new_predicate("define_item_target");
	predicate get_item <- new_predicate("get_item");
	predicate wander <- new_predicate("wander");
	predicate return_company <- new_predicate("return_company");
	
	predicate sac <- new_predicate("sac",["contenance"::5]);
	
	//we define in the same way a belief that I have already item that I have to return to the base
	predicate has_item <- new_predicate("has_item");
	
	point target;
	
	//at the creation of the agent, we add the desire to patrol (wander)
	init
	{
		agent friend <- nil;
		
		do add_social_link(new_social_link(friend));
		
		emotion joie <- new_emotion("joie",wander);
		do add_emotion(joie);
		
		do add_desire(wander);
	}
	
	//if the agent perceive a item in its neighborhood, it adds a belief concerning its location and remove its wandering intention
	perceive target:item in:viewdist {
		focus id:"location_item" var:location;
		ask myself {do remove_intention(wander, false);}
	}
	
	//if the agent has the belief that their is item at given location, it adds the desire to get item
	rule belief: new_predicate("location_item") new_desire: get_item strength:10.0;
	//if the agent has the belief that it has gold, it adds the desire to return to the base
	rule belief: has_item new_desire: return_company strength:100;
	
	// plan that has for goal to fulfill the wander desire	
	plan letsWander intention:wander 
	{
		do wander amplitude: 60.0;
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
	
	////plan that has for goal to fulfill the return to base desire
	plan return_to_company intention: return_company{
		do goto target: the_company ;
		if (the_company.location = location)  {
			do remove_belief(has_item);
			do remove_intention(return_company, true);
			the_company.itens <- the_company.itens + 1;
		}
	}
	
	aspect default {
	  draw circle(2) color: #red border:#black;
	  draw circle(viewdist) color:rgb(#yellow,0.5);
	  draw ("B:" + length(belief_base) + ":" + belief_base) color:#black size:4; 
	  draw ("D:" + length(desire_base) + ":" + desire_base) color:#black size:4 at:{location.x,location.y+4}; 
	  draw ("I:" + length(intention_base) + ":" + intention_base) color:#black size:4 at:{location.x,location.y+2*4}; 
	  draw ("curIntention:" + get_current_intention()) color:#black size:4 at:{location.x,location.y+3*4};
	  draw ("possible_itens:" + get_current_intention()) color:#black size:4 at:{location.x,location.y+4*4}; 		
	}
}

species item {	
	aspect default {
		draw triangle(0.5) color: color border: #black;
	}	
}

species company {
	int itens;
	aspect default
	{
	  draw square(20) color: #blue;
	}
}

grid grille width: 25 height: 25 neighbors:4 {
	rgb color <- #white;
}

experiment MBTI type: gui {
	float minimum_cycle_duration <- 0.05;
	/** Insert here the definition of the input and output of the model */
	output {
		display map {
			grid grille lines: #darkgreen;
			species company;			
			species people aspect:default;
			species item;			
		}		
	}
}

