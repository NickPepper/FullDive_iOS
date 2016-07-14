uniform mat4 u_MVP;

attribute vec4 a_Position;

varying vec2 v_CurrentPosition;

void main() {
    v_CurrentPosition = a_Position.xy;
    gl_Position = u_MVP * a_Position;
}