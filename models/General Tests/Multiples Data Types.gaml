/**
* Name: MultiplesDataTypes
* Based on the internal empty template. 
* Author: lubraz
* Tags: 
*/

model MultiplesDataTypes

species declaring_attributes {

map map_multiple_types_1 <- ["agent":: "1", "Second_int":: 2, "Third_float":: 10.0];
map map_multiple_types_2 <- ["agent":: "2", "Second_int":: 2, "Third_float":: 10.0];
list<map> list_of_maps;

init {
	write "== DECLARING MATRIX ==";
	add map_multiple_types_1 to: list_of_maps;
	add map_multiple_types_2 to: list_of_maps;
	write list_of_maps[0];
	write list_of_maps[1];
}

}

experiment Attributes type: gui {
	user_command "Declaring attributes" {create declaring_attributes;}
}