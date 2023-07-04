shader_type spatial;
render_mode unshaded;

uniform bool enabled;

bool point_in_triangle(vec2 A, vec2 B, vec2 C, vec2 P)
{
	float s1 = C.y - A.y;
	float s2 = C.x - A.x;
	float s3 = B.y - A.y;
	float s4 = P.y - A.y;
	
	float w1 = (A.x * s1 + s4 * s2 - P.x * s1) / (s3 * s2 - (B.x-A.x) * s1);
	float w2 = (s4- w1 * s3) / s1;
	
	return w1 >= 0.0 && w2 >= 0.0 && (w1 + w2) <= 1.0;
}

//acts as the vertex colors are srgb in the standard godot material 
vec3 srgb_albedo(vec3 color)
{
	color = mix(pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)),vec3(2.4)),color.rgb.rgb * (1.0 / 12.92),lessThan(color.rgb,vec3(0.04045)));
	return color;
}

void fragment() {
	float HEXAGON_WIDTH = sqrt(3.0)/2.0;
	
	float border_size = 0.025;
	float half_border = border_size/2.0;
	float edge_offset = 0.5-HEXAGON_WIDTH/2.0;
	
	// Outter hexagon
	vec2 OUTER_TOP = vec2(HEXAGON_WIDTH/2.0,0.0);
	vec2 OUTER_TOP_LEFT = vec2(0.0,0.25);
	vec2 OUTER_TOP_RIGHT = vec2(HEXAGON_WIDTH,0.25);
	
	vec2 OUTER_BOTTOM = vec2(HEXAGON_WIDTH/2.0,1.0);
	vec2 OUTER_BOTTOM_LEFT = vec2(0.0,0.75);
	vec2 OUTER_BOTTOM_RIGHT = vec2(HEXAGON_WIDTH,0.75);
	
	// Inner hexagon
	vec2 INNER_TOP = vec2(0.5,0.0+border_size);
	vec2 INNER_TOP_LEFT = vec2(0.0+edge_offset+border_size,0.25+half_border);
	vec2 INNER_TOP_RIGHT = vec2(1.0-edge_offset-border_size,0.25+half_border);
	
	vec2 INNER_BOTTOM = vec2(0.5,1.0-border_size);
	vec2 INNER_BOTTOM_LEFT = vec2(0.0+edge_offset+border_size,0.75-half_border);
	vec2 INNER_BOTTOM_RIGHT = vec2(1.0-edge_offset-border_size,0.75-half_border);
	
	ALBEDO = COLOR.xyz;
	
	//float distance_to_inner_hexagon;
	//float edge_fade = smoothstep(1.0, 0.0, distance_to_inner_hexagon);
	float edge_viscocity = 0.185;
	
	if (enabled)
	{ /*
		if (!(point_in_triangle(OUTER_TOP,OUTER_TOP_LEFT,OUTER_TOP_RIGHT,UV) || point_in_triangle(OUTER_BOTTOM,OUTER_BOTTOM_LEFT,OUTER_BOTTOM_RIGHT,UV) || point_in_triangle(OUTER_TOP_LEFT,OUTER_TOP_RIGHT,OUTER_BOTTOM_LEFT,UV) || point_in_triangle(OUTER_BOTTOM_LEFT,OUTER_BOTTOM_RIGHT,OUTER_TOP_RIGHT,UV)))
		{
			ALBEDO = vec3(COLOR.xyz-edge_viscocity);
		}*/
		
		if (!(point_in_triangle(INNER_TOP,INNER_TOP_LEFT,INNER_TOP_RIGHT,UV) || point_in_triangle(INNER_BOTTOM,INNER_BOTTOM_LEFT,INNER_BOTTOM_RIGHT,UV) || point_in_triangle(INNER_TOP_LEFT,INNER_TOP_RIGHT,INNER_BOTTOM_LEFT,UV) || point_in_triangle(INNER_BOTTOM_LEFT,INNER_BOTTOM_RIGHT,INNER_TOP_RIGHT,UV)))
		{
			ALBEDO = vec3(COLOR.xyz-edge_viscocity);
		}
		
		vec2 center = vec2(UV.x-0.5, UV.y-0.5); 
		
		if (!(length(center) > 0.435))
		{
			//ALBEDO = vec3(0.0);
			ALBEDO = COLOR.xyz;
		}
	}
	
	ALBEDO = srgb_albedo(ALBEDO);
}
