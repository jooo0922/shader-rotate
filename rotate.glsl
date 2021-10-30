#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.14159265359 // rotate2d() 함수에서 매개변수로 각도값을 넘겨줄 때, 라디안 단위로 변환해서 넘겨주기 위해 곱하는 PI 값

uniform vec2 u_resolution;
uniform float u_time;

// shader-translate 예제에서 사용했던 bar() 함수와 동일하게 직사각형 그리는 함수
// 구체적인 설명 정리는 해당 예제 참고할 것.
float rect(vec2 loc, vec2 size, vec2 coord) {
  // 직사각형의 좌하단(sw)과 우상단(ne) 좌표를 정해주는 것임.
  vec2 sw = loc - size / 2.;
  vec2 ne = loc + size / 2.;

  float pad = 0.001; // 이전 예제와 달리 리턴값을 smoothstep()으로 계산할 거라서 sw나 ne에 더해주거나 빼줄 offset(padding)값이라고 보면 됨.
  vec2 ret = smoothstep(sw - pad, sw, coord);
  ret -= smoothstep(ne, ne + pad, coord);

  // ret 값은 padding 안쪽 영역에서는 (1, 1)이고, padding 바깥 영역은 무조건 0을 하나 이상 포함하고 있으며,
  // padding 영역은 보간된 값으로 계산되고 있으므로 0 ~ 1 사이의 값으로 된 좌표값이 할당될거임.
  // 따라서, padding 안쪽 영역은 1이 리턴되고, padding 바깥쪽 영역은 0,
  // padding 영역은 0 ~ 1 사이의 보간된 값들끼리 빼준 값이 리턴되겠지!
  return (ret.x * ret.y);
}

// 이전 예제에서 썼던 것처럼 십자가 도형을 그리는 함수
// 그런데, 사실 함수 이름을 cross로 하는 것은 좋지 못하다.
// 왜냐면, 셰이더 내장함수 중에서 외적연산을 담당하는 cross() 라는 built-in 함수가 이미 존재하기 때문에,
// 내장함수의 이름을 그대로 써서 사용자 정의 함수를 만드는 건 사실 지양해야 함.
// 다만 이전 예제에서도 그렇게 사용했으니 그냥 쓰겠다고 함.
float cross(vec2 loc, vec2 size, vec2 coord) {
  float r1 = rect(loc, size, coord); // 가로로 누워있는 직사각형
  float r2 = rect(loc, size.yx, coord); // 세로로 누워있는 직사각형 -> size의 가로, 세로를 바꿔주면 되기 때문에 swizzle 문법을 사용해서 넘겨줌. (shader-color 예제 참고.)

  // r1, r2 값 중 적어도 하나가 1로 리턴된다면(즉, 적어도 하나라도 직사각형 영역에 속한다면) 
  // max() 내장함수를 통해 1을 리턴해주도록 함.
  return max(r1, r2);
}

// 2D 회전 변환에 필요한 2*2 행렬을 생성하여 리턴해주는 함수 (thebookofshader.com 에서 가져옴.)
// 매개변수로 각도값을 넘겨받은 뒤, 그 각도값의 sin, cos 값으로 2*2 회전행렬을 만듦.
// 사실 회전행렬은 회전축이 어디냐에 따라 행렬 구성이 달라지기도 해서... 
// 회전행렬을 어떻게 만드는건지, 어떻게 변환시키는지 등의 자세한 내용은 WebGL 책을 참고할 것!
mat2 rotate2d(float _angle) {
  return mat2(cos(_angle), -sin(_angle), sin(_angle), cos(_angle));
}

void main() {
  vec2 coord = gl_FragCoord.xy / u_resolution; // 각 픽셀들 좌표값 normalize
  coord = coord * 2. - 1.; // 원점을 좌하단에서 캔버스 정가운데로 옮기기 위해 각 픽셀들 좌표값 Mapping
  coord.x *= u_resolution.x / u_resolution.y; // 캔버스를 resizing 해도 도형 왜곡이 없도록 해상도 비율값을 곱해줌.

  // 이 rotate2d() 함수를 사용할 때 주의할 점은, 원점을 제대로 정해야 한다는 것.
  // 위에 코드에서 원점을 캔버스 중앙으로 옮기는 코드를 작성한 이유가 그거임.
  // 이 함수에서 리턴해 준 2*2 회전행렬을 각 픽셀들의 좌표값에 곱해주면,
  // 십자가는 '원점'을 중심점으로 회전하게 되어있음. 즉, 회전의 중심이 (0, 0)이 되는 것.
  // 따라서, 원점이 캔버스 좌하단에 있는지, 캔버스 정가운데에 있는지에 따라
  // 십자가가 어디에서 회전하는지, 자전하는지, 공전하는지 등의 회전의 형태가 달라짐!
  // 마치 콤파스를 이용해서 원을 그릴 때, 뾰족한 쇠를 박아서 지지하는 부분이 여기서는 원점이라고 생각하면 됨!
  // coord = coord * rotate2d(u_time * PI);
  // 만약 u_time을 sin() 함수에 넣은 뒤, sin값으로 회전을 시키면,
  // sin값은 -1 ~ 1 사이의 값을 주기적으로 리턴해주므로, 일정 주기에 따라 회전방향을 틀면서 회전함.
  coord = coord * rotate2d(sin(u_time) * PI);

  vec3 col = vec3(cross(vec2(.0), vec2(.55, .07), coord));
  gl_FragColor = vec4(col, 1.);
}

/*
  프래그먼트 셰이더에서 회전 변환


  이전 예제에서 프래그먼트 셰이더로 이동 변환을 구현할 때에는
  굳이 행렬을 사용하지 않고도 작업을 할 수 있었지만,

  회전 변환을 프래그먼트 셰이더로 구현하려면
  각 픽셀들의 좌표값에 회전 행렬을 곱해줘야 함!

  물론 여기서는 WebGL에서 사용하던 mat4 행렬을 사용하는 게 아니라,
  2D 좌표계에서의 회전을 구현하는 데 필요한 mat2 행렬 데이터를 사용할 것임.
*/

/*
  rotate2d() 함수가 리턴해주는 회전행렬은 '왼손 법칙'을 따름

  이게 무슨 말이냐면,
  왼손으로 따봉을 만들고, 엄지손가락이 나를 향하도록 눕혀보면,
  나머지 4개의 손가락이 시계방향으로 넘어가는 걸 볼 수 있음.

  이 때, 엄지손가락이 양의 z축이고, 나머지 4개 손가락의 방향이
  rotate2d() 함수에 넣는 각도가 커질수록(양의 방향으로 증가할수록) 
  물체가 회전하는 방향이라고 생각하면 됨.


  GLSL(셰이더)가 전부 왼손 법칙을 따른다는 게 아니다! 
  이거를 주의해야 함!

  실제로 WebGL 책에서는 
  버텍스 셰이더로 전송해 준 4*4 회전행렬로 
  각 버텍스를 회전시킬 때, '오른손 법칙'을 따라 물체(버텍스)가 회전한다고 설명되어 있음.
  
  내가 생각해봤을 때, 이거는 어떤 회전행렬을 각각의 버텍스 (여기서는 픽셀의 좌표값들)에
  곱해주느냐에 따라 왼손법칙 / 오른손법칙 이 결정되는 것 같음.

  WebGL 책에서 설명하는 회전행렬과 rotate2d() 함수에서 사용하는 회전행렬이 서로 다르기 때문!
*/