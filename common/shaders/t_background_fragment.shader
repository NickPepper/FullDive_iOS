precision mediump float;
uniform sampler2D v_Texture;
varying vec2 texCoord;

void main() {
   gl_FragColor = vec4(texture2D(v_Texture, texCoord).rgb, 0.7);
}