#version 330 core

uniform float iZoom;
uniform vec2 iScreen;
uniform vec2 iMouse;
uniform vec2 iMove;

out vec4 frag_color;

#define E 2.71828182845904523536028747135266250
#define ESCAPE 1000.
#define PI 3.141592653

vec2 cx_mul(vec2 a,vec2 b){
	return vec2(a.x*b.x-a.y*b.y,a.x*b.y+a.y*b.x);
}

vec2 cx_sqr(vec2 a){
	float x2=a.x*a.x;
	float y2=a.y*a.y;
	float xy=a.x*a.y;
	return vec2(x2-y2,xy+xy);
}

vec2 cx_cube(vec2 a){
	float x2=a.x*a.x;
	float y2=a.y*a.y;
	float d=x2-y2;
	return vec2(a.x*(d-y2-y2),a.y*(x2+x2+d));
}

vec2 cx_div(vec2 a,vec2 b){
	float denom=1./(b.x*b.x+b.y*b.y);
	return vec2(a.x*b.x+a.y*b.y,a.y*b.x-a.x*b.y)*denom;
}

vec2 cx_sin(vec2 a){
	return vec2(sin(a.x)*cosh(a.y),cos(a.x)*sinh(a.y));
}

vec2 cx_cos(vec2 a){
	return vec2(cos(a.x)*cosh(a.y),-sin(a.x)*sinh(a.y));
}

vec2 cx_exp(vec2 a){
	return exp(a.x)*vec2(cos(a.y),sin(a.y));
}

vec2 fractal_f(vec2 z,vec2 c){
	return cx_sqr(z) + c;
}

#define DO_LOOP(name)\
float smooth_i;\
for(i=0;i<ESCAPE;++i){\
	z=name(z,c);\
	if(dot(z,z)>ESCAPE){\
	    float mod = sqrt(dot(z, z));\
	    smooth_i = float(i) - log2(max(1.0f, log2(mod)));\
	    break;\
	}\
}

vec3 gradient(float n){
	float div=1.f/ESCAPE;
	float red=10.f*n*div;
	float green=5.f*n*div-.5f;
	float blue=(6.f*n-9.f)/(2.f*(4.f*ESCAPE-6.f));
	return vec3(red,green,blue);
}

vec3 fractal(vec2 z,vec2 c){
	vec2 pz=z;
	int i;
	DO_LOOP(fractal_f);
	if (i < ESCAPE) {
	 return gradient(smooth_i);
	}
	return gradient(i);
}

void main(){
	vec2 screen_pos=gl_FragCoord.xy-(iScreen.xy*.5);
	vec3 col=vec3(0.,0.,0.);
	vec2 c=vec2((screen_pos-iMove)*vec2(1.,-1.)*iZoom);
	col+=fractal(c,c);
	gl_FragColor=vec4(clamp(col,0.,1.),1.);
}