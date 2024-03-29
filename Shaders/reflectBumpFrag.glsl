#version 150 core

uniform sampler2D diffuseTex;
uniform sampler2D bumpTex;
uniform samplerCube cubeTex;	//Automatically handles which of the 6 seperate textures the sample is from
uniform sampler2DShadow shadowTex; //NEW

uniform int specularPower;
uniform float specFactorMod;

uniform vec4 lightColour;
uniform vec3 lightPos;
uniform float lightRadius;

uniform vec3 cameraPos;

in Vertex {
	vec4 colour;
	vec2 texCoord;
	vec3 normal;
	vec3 tangent;
	vec3 binormal;
	vec3 worldPos;
	vec4 shadowProj;
} IN;

out vec4 gl_FragColor[3];

void main(void){

	//Calculate the colour the fragment would be
	vec4 diffuse = texture(diffuseTex, IN.texCoord) * IN.colour;
	
	//Create TBN matrix to convert tangent space normal into world space
	mat3 TBN = mat3(IN.tangent, IN.binormal, IN.normal);
	
	//Transform the vec3 derived from the bump map to give the world space normal. 
	// multiplication by 2 and subtraction by 1 is to convert from texture space to clip space!
	vec3 normal = normalize(TBN * (texture(bumpTex, IN.texCoord).rgb * 2.0 - 1.0));
	
	vec3 incident = normalize(IN.worldPos - cameraPos);
	
	float dist = length(lightPos - IN.worldPos);
	float atten = 1.0 - clamp(dist / lightRadius, 0.2, 1.0);
	
	float shadow = 1.0;
	
	if (IN.shadowProj.w > 0.0){
		shadow = textureProj(shadowTex, IN.shadowProj);
	}
	
	//Gives us the fragment at the vector pointed to, calculated by the reflect function given an incident
	//vector and a normal
	vec4 reflection  = texture(cubeTex, reflect(incident, normalize(normal)));
	
	vec3 viewDir = normalize(cameraPos - IN.worldPos);
	vec3 halfDir = normalize(incident + viewDir);
	
	float rFactor = max(0.0, dot(halfDir, normal));
	float sFactor = pow(rFactor, specularPower);
	
	vec3 lightedColour = (diffuse.rgb * lightColour.rgb);
	lightedColour += (lightColour.rgb * sFactor) * specFactorMod;
	
	atten *= shadow;
	// reflection *= shadow;
	
	//Blend it all together!
	// gl_FragColor = (lightColour * diffuse * atten) * (diffuse+reflection);
	gl_FragColor[0].rgb = (lightedColour * diffuse.rgb * atten) * (diffuse.rgb+reflection.rgb);
	//gl_FragColor.rgb += (lightColour.rgb * sFactor) * specFactorMod;
	
	gl_FragColor[0].a = diffuse.a;
	gl_FragColor[0].rgb += (diffuse.rgb * lightColour.rgb) * 0.1;
	
	gl_FragColor[1] = vec4(normal.xyz * 0.5 + 0.5, 1.0);
	gl_FragColor[2] = diffuse;
}