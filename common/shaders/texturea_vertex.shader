uniform mat4 u_MVP;
uniform float u_IsFloor;

attribute vec4 a_Position;
attribute vec2 v_TextCoord;

varying vec2 texCoord;
varying float v_isFloor;

void main()
{
   texCoord = v_TextCoord;
   gl_Position = u_MVP * a_Position;
   v_isFloor = u_IsFloor;
}