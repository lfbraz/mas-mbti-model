model multi_simulations

global {
    init {
        create my_species number:1;
    }
    
}

species my_species skills:[moving] {
    float my_speed <- 1.00 with_precision 2; 
    
    reflex update {
        do wander speed: my_speed;
        write "speed: " + speed + " / real_speed: " + real_speed;
    }
    aspect base {
        draw square(2) color:#blue;
    }
}

experiment my_experiment type:gui  {
    // Random Seed Control
	float seedValue <- 1985.0;
	float seed <- seedValue;
    /* 
    init {
        create simulation with:[rng::"java",seed::10.0];
        create simulation with:[rng::"java",seed::10.0];
    }
    */
    output {
        display my_display {
            species my_species aspect:base;
            graphics "my_graphic" {
                draw rectangle(35,10) at:{0,0} color:#lightgrey;
                draw rng at:{3,3} font:font("Helvetica", 20 , #plain) color:#black;
            }
        }
    }
}