precision mediump float;
uniform sampler2D v_Texture;
varying vec2 texCoord;
varying float v_isFloor;

void main() {
   gl_FragColor = texture2D(v_Texture, texCoord)*v_isFloor;
}