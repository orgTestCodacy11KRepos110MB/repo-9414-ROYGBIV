precision lowp float;
precision lowp int;

#define ALPHA_TEST 0.5
#define LOG2 1.442695

uniform float totalAlpha;
varying float vAlpha;
varying vec3 vColor;

#define INSERTION

#ifdef HAS_TEXTURE
  uniform sampler2D texture;
  #ifdef HAS_DIFFUSE
    varying vec2 vDiffuseUV;
    varying float hasDiffuseMap;
  #endif
  #ifdef HAS_EMISSIVE
    varying vec2 vEmissiveUV;
    varying float hasEmissiveMap;
  #endif
  #ifdef HAS_ALPHA
    varying vec2 vAlphaUV;
    varying float hasAlphaMap;
  #endif
  #ifdef HAS_AO
    varying vec2 vAOUV;
    varying float hasAOMap;
  #endif
#endif
#ifdef HAS_AO
  uniform float totalAOIntensity;
  varying float vAOIntensity;
#endif
#ifdef HAS_EMISSIVE
  uniform float totalEmissiveIntensity;
  uniform vec3 totalEmissiveColor;
  varying float vEmissiveIntensity;
  varying vec3 vEmissiveColor;
#endif
#ifdef HAS_SKYBOX_FOG
  uniform samplerCube cubeTexture;
  uniform vec3 cameraPosition;
  varying vec3 vWorldPosition;
#endif
#ifdef HAS_FOG
  uniform vec4 fogInfo;
#endif
#ifdef HAS_FORCED_COLOR
  uniform vec4 forcedColor;
#endif

void main(){

  #ifdef HAS_FORCED_COLOR
    if (forcedColor.x >= -10.0){
      gl_FragColor = vec4(forcedColor.y, forcedColor.z, forcedColor.w, forcedColor.x);
      return;
    }
  #endif

  vec4 diffuseColor = vec4(1.0, 1.0, 1.0, 1.0);
  #ifdef HAS_DIFFUSE
    if (hasDiffuseMap > 0.0){
      diffuseColor = texture2D(texture, vDiffuseUV);
    }
  #endif
  gl_FragColor = vec4(vColor, vAlpha) * diffuseColor;
  #ifdef HAS_ALPHA
    if (hasAlphaMap > 0.0){
      float val = texture2D(texture, vAlphaUV).g;
      gl_FragColor.a *= val;
      if (val <= ALPHA_TEST){
        discard;
      }
    }
  #endif
  #ifdef HAS_AO
    if (hasAOMap > 0.0){
      float aoIntensityCoef = vAOIntensity * totalAOIntensity;
      float ao = (texture2D(texture, vAOUV).r - 1.0) * aoIntensityCoef + 1.0;
      gl_FragColor.rgb *= ao;
    }
  #endif
  #ifdef HAS_EMISSIVE
    if (hasEmissiveMap > 0.0){
      vec4 eColor = texture2D(texture, vEmissiveUV);
      float ei = vEmissiveIntensity * totalEmissiveIntensity;
      vec3 totalEmissiveRadiance = vec3(ei, ei, ei) * vEmissiveColor * totalEmissiveColor;
      totalEmissiveRadiance *= eColor.rgb;
      gl_FragColor.rgb += totalEmissiveRadiance;
    }
  #endif
  #ifdef HAS_FOG
    #ifdef HAS_SKYBOX_FOG
      vec3 coord = normalize(vWorldPosition - cameraPosition);
      vec4 cubeTextureColor = textureCube(cubeTexture, coord) * vec4(fogInfo[1], fogInfo[2], fogInfo[3], 1.0);
      float fogDensity = -fogInfo[0];
      float z = gl_FragCoord.z / gl_FragCoord.w;
      float fogFactor = exp2(-fogDensity * fogDensity * z * z * LOG2);
      gl_FragColor = vec4(mix(cubeTextureColor.rgb, gl_FragColor.rgb, fogFactor), gl_FragColor.a);
    #else
      float fogDensity = fogInfo[0];
      float fogR = fogInfo[1];
      float fogG = fogInfo[2];
      float fogB = fogInfo[3];
      float z = gl_FragCoord.z / gl_FragCoord.w;
      float fogFactor = exp2(-fogDensity * fogDensity * z * z * LOG2);
      fogFactor = clamp(fogFactor, 0.0, 1.0);
      gl_FragColor = vec4(mix(vec3(fogR, fogG, fogB), gl_FragColor.rgb, fogFactor), gl_FragColor.a);
    #endif
  #endif

  gl_FragColor.a *= totalAlpha;
}
