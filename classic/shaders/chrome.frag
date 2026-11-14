#version 460 core
// Жидкое серебро для фона Tiyn: плавные блики и мягкая волнистая кромка.
#include <flutter/runtime_effect.glsl>
precision highp float;

uniform vec2 uSize;
uniform float uTime;
uniform float uDark;

out vec4 fragColor;

// Хэш без sin: одинаково работает на любых видеокартах.
float hash(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = p - i;
  vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0); // без швов на бликах
  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm2(vec2 p) {
  float v = 0.5 * noise(p);
  p = p * 2.02 + vec2(1.7, 9.2);
  return v + 0.25 * noise(p);
}

float fbm3(vec2 p) {
  float v = 0.5 * noise(p);
  p = p * 2.02 + vec2(1.7, 9.2);
  v += 0.25 * noise(p);
  p = p * 2.02 + vec2(1.7, 9.2);
  return v + 0.125 * noise(p);
}

float fbm4(vec2 p) {
  float v = fbm3(p);
  p = (p * 2.02 + vec2(1.7, 9.2)) * 2.02 + vec2(1.7, 9.2);
  p = p * 2.02 + vec2(1.7, 9.2);
  return v + 0.0625 * noise(p);
}

float field(vec2 p, float t) {
  float qx = fbm3(p + vec2(0.0, t * 0.05));
  float qy = fbm3(p + vec2(5.2 - t * 0.04, 1.3));
  return fbm2(p + 1.5 * vec2(qx, qy) + vec2(t * 0.02, 0.0));
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize.y; // одинаковый масштаб по обеим осям
  float t = uTime;
  vec2 p = uv * 1.15;

  float h = field(p, t);
  float e = 0.004;
  float hx = (field(p + vec2(e, 0.0), t) - h) / e;
  float hy = (field(p + vec2(0.0, e), t) - h) / e;
  vec3 n = normalize(vec3(-hx * 0.75, -hy * 0.75, 1.0));

  float env = 0.5 + 0.5 * sin(n.y * 3.2 + n.x * 1.6 + h * 12.0);
  float fres = 1.0 - n.z;
  float band = smoothstep(0.05, 0.95, env) * (1.0 - 0.5 * fres) + fres * 0.9;
  float hi = pow(clamp(env, 0.0, 1.0), 40.0);

  float mi = fbm4(uv * 1.2 + vec2(3.0 + t * 0.01, -1.0 - t * 0.008)) + 0.12 * (1.125 - uv.y / 1.2); // кромка ближе к середине
  float m = smoothstep(0.50, 0.54, mi);
  float rd = (mi - 0.52) / 0.008;
  float rim = exp(-rd * rd);

  float v = uv.y;
  vec3 base;
  vec3 chrome;
  float amt;
  if (uDark > 0.5) {
    base = vec3(0.03 + 0.03 * v, 0.03 + 0.03 * v, 0.035 + 0.03 * v);
    chrome = vec3(0.08 + 0.44 * band + 0.8 * hi) * vec3(1.0, 1.0, 1.03);
    amt = 0.75;
  } else {
    base = vec3(0.95 - 0.02 * v, 0.915 - 0.02 * v - 0.02 * (1.0 - uv.x),
                0.905 - 0.01 * v - 0.03 * (1.0 - uv.x));
    chrome = vec3(0.42 + 0.40 * band + 0.35 * hi) * vec3(1.0, 0.985, 0.99);
    amt = 0.75;
  }
  vec3 col = mix(base, chrome, m * amt) + vec3(rim * 0.25);
  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
