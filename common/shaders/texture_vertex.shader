uniform mat4 u_MVP;

attribute vec4 a_Position;
attribute vec2 v_TextCoord;

varying vec2 texCoord;

void main()
{
   texCoord = v_TextCoord;
   gl_Position = u_MVP * a_Position;
}