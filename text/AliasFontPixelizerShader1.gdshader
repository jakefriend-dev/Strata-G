shader_type canvas_item;

uniform bool active = true;
//uniform bool pixel_font = false;

uniform float threshold_lone : hint_range(0.0, 1.0) = 0.625;
uniform vec4 body_col: hint_color =  vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 edge_col: hint_color =  vec4(0.679, 0.702, 0.639, 1.0);
uniform vec4 shade_col: hint_color =  vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 light_col: hint_color = vec4(0.914, 0.910, 0.780, 1.0);
uniform bool use_dual_thresholds = false;
uniform float threshold_hard : hint_range(0.0, 1.0) = 0.75; // Should be higher!
uniform float threshold_soft : hint_range(0.0, 1.0) = 0.50; // Should be lower!
uniform bool use_soft_inner_corners = false;
uniform bool use_standard_shadow = false;

uniform bool use_thin_hlines = false;

////////////////////////////////////////////////

void fragment() {
	vec4 pcol = texture(TEXTURE, UV); // Get the current pixel colour value
	
	if (!active) {
		pcol.r = body_col.r;
		pcol.g = body_col.g;
		pcol.b = body_col.b;
		}
	else {
		
		bool hard = false;
		bool mid = false;
		bool soft = false;
		bool light = false;
		float a = texture(TEXTURE, UV).a;
		vec2 ps = TEXTURE_PIXEL_SIZE; // Overall pixel size of the texture
		
		if (true) {
//		if (!pixel_font) {
			if (use_dual_thresholds) {pcol.a = step(threshold_hard, a);}
			else {pcol.a = step(threshold_lone, a);}
			hard = bool(pcol.a);
			
			// Apply second (lower) threshold)
			if (!hard && use_dual_thresholds && threshold_soft < threshold_hard) {
				pcol.a = step(threshold_soft, a);
				mid = bool(pcol.a);
				}
			}
//		else {
//			hard = bool(pcol.a);
//		}
		
		if ((use_soft_inner_corners || use_standard_shadow) && !hard) { // Either soft or nothing
			
			float au = step(threshold_hard, texture(TEXTURE, UV + vec2( 0.0, -1.0) * ps)).a;
			float aul= step(threshold_hard, texture(TEXTURE, UV + vec2(-1.0, -1.0) * ps)).a;
			float al = step(threshold_hard, texture(TEXTURE, UV + vec2(-1.0,  0.0) * ps)).a;
			float ad = step(threshold_hard, texture(TEXTURE, UV + vec2( 0.0,  1.0) * ps)).a;
			float ar = step(threshold_hard, texture(TEXTURE, UV + vec2( 1.0,  0.0) * ps)).a;
			
			if (use_standard_shadow) {
				if (!soft && aul > 0.5) {soft = true;} // Very simple!
			}
			
			if (use_soft_inner_corners) {
				// Dark lower-right
				if (!soft && !light && au > 0.5 && al > 0.5) {
//					soft = true;
					if (mid) {
						}
					else {
						soft = true;
						}
					}
				
				// The 'mids' of lowerleft and upperright
				if (!soft && !light && au > 0.5 && ar > 0.5) {
//					soft = true;
					if (mid) {
						}
					else {
						soft = true;
						}
					}
				if (!soft && !light && ad > 0.5 && al > 0.5) {
//					soft = true;
					if (mid) {
						}
					else {
						soft = true;
						}
					}
				
				// Light upper-left
				if (!soft && !light && ad > 0.5 && ar > 0.5) {
//					light = true;
					if (mid) {
						}
					else {
						light = true;
						}
					}
			}
		}
		
		if (use_thin_hlines) {
			float auu = texture(TEXTURE, UV + vec2( 0.0, -2.0) * ps).a;
			float au =  texture(TEXTURE, UV + vec2( 0.0, -1.0) * ps).a;
			float ad =  texture(TEXTURE, UV + vec2( 0.0,  1.0) * ps).a;
			float ald = texture(TEXTURE, UV + vec2(-1.0,  1.0) * ps).a;
			float ard = texture(TEXTURE, UV + vec2( 1.0,  1.0) * ps).a;
			if (pcol.a > 0.5) {
				if (au > 0.5) {
					if (auu < 0.5) {
						if (ad < 0.5) {
//							if (ald > 0.5 || ard > 0.5) {
								mid = true;
//							}
						}
					}
				}
			}
		}
		
		
		
		
		
		
		
		if (hard) {
			pcol.a = 1.0;
			pcol.r = body_col.r;
			pcol.g = body_col.g;
			pcol.b = body_col.b;
			}
		if (mid) {
			pcol.a = 1.0;
			pcol.g = edge_col.g;
			pcol.r = edge_col.r;
			pcol.b = edge_col.b;
			}
		if (soft) {
			pcol.a = 1.0;
			pcol.g = shade_col.g;
			pcol.r = shade_col.r;
			pcol.b = shade_col.b;
			}
		if (light) { 
			pcol.a = 1.0;
			pcol.g = light_col.g;
			pcol.r = light_col.r;
			pcol.b = light_col.b;
			}
	}
	
	COLOR = pcol;
}