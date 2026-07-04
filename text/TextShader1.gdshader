shader_type canvas_item;

uniform bool active = true;

uniform int unfilled_checkheight = 7;
uniform int unfilled_checkwidth = 4;

uniform vec4 body_col: hint_color =  vec4(0.267, 0.216, 0.357, 1.0);
uniform vec4 shade_col: hint_color =  vec4(0.679, 0.702, 0.639, 1.0);

void fragment() {
	vec4 pcol = texture(TEXTURE, UV); // Get the current pixel colour value
	
	if (!active) {
		pcol.r = body_col.r;
		pcol.g = body_col.g;
		pcol.b = body_col.b;
		}
	else {
		
		vec4 col = texture(TEXTURE, UV);
		vec2 ps = TEXTURE_PIXEL_SIZE; // Overall pixel size of the texture
		
		if (col.a > 0.5) {
		
			float au = texture(TEXTURE, UV + vec2( 0.0, -1.0) * ps).a;
			float aul= texture(TEXTURE, UV + vec2(-1.0, -1.0) * ps).a;
			float al = texture(TEXTURE, UV + vec2(-1.0,  0.0) * ps).a;
			float ad = texture(TEXTURE, UV + vec2( 0.0,  1.0) * ps).a;
			float adl= texture(TEXTURE, UV + vec2(-1.0,  1.0) * ps).a;
			float ar = texture(TEXTURE, UV + vec2( 1.0,  0.0) * ps).a;
			
//			bool low = true;
//
//			if (low) {
//				pcol = shade_col;
//			}
			
			if (ar < 0.5 && al > 0.5 && au > 0.5 && aul > 0.5 && adl > 0.5) {
				pcol = shade_col;
			}
			
			
			else {
				pcol = body_col;
			}
		}
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
//		bool hard = false;
//		bool mid = false;
//		bool soft = false;
//		bool light = false;
//
//		if (true) {
//			if (use_dual_thresholds) {pcol.a = step(threshold_hard, a);}
//			else {pcol.a = step(threshold_lone, a);}
//			hard = bool(pcol.a);
//
//			// Apply second (lower) threshold)
//			if (!hard && use_dual_thresholds && threshold_soft < threshold_hard) {
//				pcol.a = step(threshold_soft, a);
//				mid = bool(pcol.a);
//				}
//			}
//
//		if ((use_soft_inner_corners || use_standard_shadow) && !hard) { // Either soft or nothing
//
////			float au = step(threshold_hard, texture(TEXTURE, UV + vec2( 0.0, -1.0) * ps)).a;
////			float aul= step(threshold_hard, texture(TEXTURE, UV + vec2(-1.0, -1.0) * ps)).a;
////			float al = step(threshold_hard, texture(TEXTURE, UV + vec2(-1.0,  0.0) * ps)).a;
////			float ad = step(threshold_hard, texture(TEXTURE, UV + vec2( 0.0,  1.0) * ps)).a;
////			float ar = step(threshold_hard, texture(TEXTURE, UV + vec2( 1.0,  0.0) * ps)).a;
//
//			if (use_standard_shadow) {
//				if (!soft && aul > 0.5) {soft = true;} // Very simple!
//			}
//
//			if (use_soft_inner_corners) {
//				// Dark lower-right
//				if (!soft && !light && au > 0.5 && al > 0.5) {
//					if (mid) {
//						}
//					else {
//						soft = true;
//						}
//					}
//
//				// The 'mids' of lowerleft and upperright
//				if (!soft && !light && au > 0.5 && ar > 0.5) {
//					if (mid) {
//						}
//					else {
//						soft = true;
//						}
//					}
//				if (!soft && !light && ad > 0.5 && al > 0.5) {
//					if (mid) {
//						}
//					else {
//						soft = true;
//						}
//					}
//
//				// Light upper-left
//				if (!soft && !light && ad > 0.5 && ar > 0.5) {
//					if (mid) {
//						}
//					else {
//						light = true;
//						}
//					}
//			}
//		}
//
//
//		if (hard) {
//			pcol.a = 1.0;
//			pcol.r = body_col.r;
//			pcol.g = body_col.g;
//			pcol.b = body_col.b;
//			}
//		if (mid) {
//			pcol.a = 1.0;
//			pcol.g = edge_col.g;
//			pcol.r = edge_col.r;
//			pcol.b = edge_col.b;
//			}
//		if (soft) {
//			pcol.a = 1.0;
//			pcol.g = shade_col.g;
//			pcol.r = shade_col.r;
//			pcol.b = shade_col.b;
//			}
//		if (light) { 
//			pcol.a = 1.0;
//			pcol.g = light_col.g;
//			pcol.r = light_col.r;
//			pcol.b = light_col.b;
//			}
	}
	
	COLOR = pcol;
}