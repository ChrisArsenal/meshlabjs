precision highp float;

uniform mat4 lightViewProjection;
uniform mat4 modelMatrix;

uniform sampler2D colorMap;
uniform sampler2D positionMap;
uniform sampler2D depthMap;
uniform sampler2D vBlurMap;
uniform sampler2D hBlurMap;

uniform float intensity;

varying vec2 vUv;

float shadowContribution(vec2 moments, float t) {

  if (t <= moments.x) return 1.0;//bound della funzione di Chebyshev

  float m1_2 = moments.x * moments.x;
  float variance = moments.y - m1_2; // var = E(x^2) - E(x)^2;

  variance = max(variance, 0.000001);

  float d = t - moments.x;
  float pmax = variance / (variance + (d*d));

  return pmax;
}

float shadowCalc(vec2 vUv){

  vec4 position = texture2D(positionMap, vUv); //posizione mondo
  vec4 lightSpacePosition =  lightViewProjection * position;

  //perspective devide
  lightSpacePosition.xyz /=  lightSpacePosition.w;

  //linearize in [0..1]
  lightSpacePosition.xyz = lightSpacePosition.xyz * vec3(0.5) + vec3(0.5);

  //sample texture
  vec2 moments = mix(texture2D(hBlurMap, lightSpacePosition.xy).xy,
                        texture2D(vBlurMap, lightSpacePosition.xy).xy, 0.5);

  float fragDepth = lightSpacePosition.z;

  return shadowContribution(moments, fragDepth);
}

void main(){
  vec4 color = texture2D(colorMap, vUv);

  if (color.a == 0.0) discard;

  float chebishev = shadowCalc(vUv);
  /* se probabilità di essere in luce >= 50% allora sono in luce */
  /* ==> shadowing prende : 0.6; 0.7; 0.8; 0.9; 1.0 */
  /* per supportare intensity voglio andare da 0 a 1, ossia se sono in ombra
      ma trasparenza a 1 => voglio shadowing = 1.0 */


//  float shadowing = (chebishev > 0.4) ? 1.0 : (0.6 + chebishev);

  if (chebishev > 0.6)
    gl_FragColor = vec4(color.rgb, color.a);
  else {
    float shadowing = clamp(0.4 + chebishev, 0.7, 1.0) * intensity;
    gl_FragColor = vec4(color.rgb * (shadowing), color.a);

  }


}
