#extension GL_OES_EGL_image_external : require
precision mediump float;
uniform samplerExternalOES u_Texture;
varying vec2 v_TextCoord;

void main() {
   gl_FragColor = texture2D(u_Texture, v_TextCoord);
}