precision mediump float;

varying vec4 v_Color;
varying vec3 v_Grid;

void main() {
    // calculate world-space distance
    float depth = gl_FragCoord.z / gl_FragCoord.w;

    if ((mod(abs(v_Grid[0]), 10.0) < 0.1) || (mod(abs(v_Grid[2]), 10.0) < 0.1)) {
        gl_FragColor = max(0.0, (90.0-depth) / 90.0) * vec4(1.0, 1.0, 1.0, 1.0)
                    + min(1.0, depth / 90.0) * v_Color;
    } else {
        gl_FragColor = v_Color;
    }
}