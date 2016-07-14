#extension GL_OES_EGL_image_external : require
precision mediump float;
uniform samplerExternalOES v_Texture;

varying vec2 texCoord;

void main() {
    gl_FragColor = texture2D(v_Texture, texCoord);
}