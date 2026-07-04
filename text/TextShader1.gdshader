shader_type canvas_item;

uniform bool active = true;

uniform int unfill_height = 7;
//uniform float border_size = 1.0;
//uniform int unfilled_checkwidth = 4;

uniform int type: hint_range(0, 5) = 0 ;

uniform vec4 col_body:   hint_color =  vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 col_shadow: hint_color =  vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 midcol_blue:  hint_color =  vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 midcol_brown:  hint_color =  vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 midcol_gray:  hint_color =  vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 midcol_red:  hint_color =  vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 midcol_custom:  hint_color =  vec4(1.0, 1.0, 1.0, 1.0);
const vec4 trans = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 white = vec4(1.0, 1.0, 1.0, 1.0);

varying vec2 og_vertex;
varying vec2 og_uv;

void vertex() {
	og_uv = UV;
	og_vertex = VERTEX;
}

void fragment() {
	vec4 pcol = texture(TEXTURE, og_uv); // Get the current pixel colour value
	
	if (!active) {
//		pcol.r = body_col.r;
//		pcol.g = body_col.g;
//		pcol.b = body_col.b;
		}
	else {
		
		vec4 col = texture(TEXTURE, UV);
		vec2 ps = TEXTURE_PIXEL_SIZE; // Overall pixel size of the texture
		
		vec4 col_shade = white;
		if (type == 1) {col_shade = midcol_blue;}
		else if (type == 2) {col_shade = midcol_brown;}
		else if (type == 3) {col_shade = midcol_gray;}
		else if (type == 4) {col_shade = midcol_red;}
		else if (type == 5) {col_shade = midcol_custom;}
		
		if (col != black) {
		
			vec4 au = texture(TEXTURE, og_uv + vec2( 0.0, -1.0) * ps);
			vec4 aul= texture(TEXTURE, og_uv + vec2(-1.0, -1.0) * ps);
			vec4 al = texture(TEXTURE, og_uv + vec2(-1.0,  0.0) * ps);
			vec4 ad = texture(TEXTURE, og_uv + vec2( 0.0,  1.0) * ps);
			vec4 adl= texture(TEXTURE, og_uv + vec2(-1.0,  1.0) * ps);
			vec4 ar = texture(TEXTURE, og_uv + vec2( 1.0,  0.0) * ps);
			
			bool low = false;
			
			if (og_vertex.y > float(unfill_height)) {
				low = true;
			}
			
			if (low) {
				if (aul == black && al == black && ar != black && ad != black) {
					pcol = col_body;
				}
				
				else {
					pcol = col_shade;
				}
				
			}
			
			else if (ar == black && al != black && au != black && aul != black && adl != black) {
				pcol = col_shade;
			}
			
			else {
				pcol = col_body;
			}
		}
		
		else { // Typically transparent, so HERE we draw a shadow! (?)
			
			vec4 ul = texture(TEXTURE, og_uv + vec2(-1.0, -1.0) * ps);
			if (ul != black) {
				pcol = col_shadow;
			}
			else {
				pcol = trans;
			}
		}
	}
	
	COLOR = pcol;
}