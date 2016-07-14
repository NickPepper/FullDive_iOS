precision highp float;
uniform vec2 u_Size;
uniform vec3 u_Color;
uniform float u_Border;
uniform float u_ScreenPadding;

varying vec2 v_CurrentPosition;

void main() {
    vec4 black = vec4(0.0, 0.0, 0.0, 1.0);
    vec4 color;
    if (u_Color.r > 0.05 && u_Color.g > 0.05 && u_Color.b > 0.05) {
        color = vec4(u_Color, 0.7);
    } else {
        color = vec4(1.0, 1.0, 1.0, 0.7);
    }
    float bloomBorder = u_Border - u_ScreenPadding;
    float twiceBloomBorder = 2.0 * bloomBorder;
    if (abs(v_CurrentPosition.x) < (u_Size.x - bloomBorder) && abs(v_CurrentPosition.y) < (u_Size.y - bloomBorder)) {
        gl_FragColor = black;
        return;
    }
    if (abs(v_CurrentPosition.x) > (u_Size.x - twiceBloomBorder) && abs(v_CurrentPosition.y) > (u_Size.y - twiceBloomBorder)) {
        float currRadius = length(abs(v_CurrentPosition) - (u_Size - twiceBloomBorder));
        gl_FragColor = mix(color, black, currRadius / twiceBloomBorder);
        return;
    }
    if (abs(v_CurrentPosition.x) > (u_Size.x - twiceBloomBorder)) {
        gl_FragColor = mix(black, color, (u_Size.x - abs(v_CurrentPosition.x)) / twiceBloomBorder);
    } else {
        gl_FragColor = mix(black, color, (u_Size.y - abs(v_CurrentPosition.y)) / twiceBloomBorder);
    }
}