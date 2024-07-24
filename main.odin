package main

import "core:fmt"
import "core:strings"
import math "core:math/linalg"
import "vendor:glfw"
import gl "vendor:OpenGL"

Vec2 :: [2]f32;

screen_width:i32 = 1000;
screen_height:i32 = 700;

VAO, VBO: u32
shaderProgram: u32

init :: proc() {
	lastTime = glfw.GetTime()
	zero:uintptr = 0;
	// set up vertex data (and buffer(s)) and configure vertex attributes

    gl.GenVertexArrays(1, &VAO);
    gl.BindVertexArray(VAO);

	vertices := [?]f32{
        -1.0, -1.0,
         1.0, -1.0,
        -1.0,  1.0,
         1.0,  1.0,
    };
	
	gl.GenBuffers(1, &VBO);

    gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), &vertices[0], gl.STATIC_DRAW);

    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 0, zero);

	// screen color
	gl.ClearColor(0.2, 0.3, 0.3, 1.0);

	shader_success: bool;
	shaderProgram, shader_success = gl.load_shaders("shaders/shader_lines.vert", "shaders/shader_lines.frag");

	// mouse move
	gl.UseProgram(shaderProgram);
	vertexLocation := gl.GetUniformLocation(shaderProgram, "iMove");
	gl.Uniform2f(vertexLocation, 0, 0);
	vertexLocation = gl.GetUniformLocation(shaderProgram, "iZoom");
	gl.Uniform1f(vertexLocation, f32(1 / zoom));
	vertexLocation = gl.GetUniformLocation(shaderProgram, "iMouse");
	gl.Uniform2f(vertexLocation, 0, 0);
	vertexLocation = gl.GetUniformLocation(shaderProgram, "iScreen");
	gl.Uniform2f(vertexLocation, f32(screen_width), f32(screen_height));
}

title := ""

render :: proc() {
	currentTime := glfw.GetTime();
	
	p:uintptr = 0
	zero:rawptr = &p

	gl.Clear(gl.COLOR_BUFFER_BIT);
	gl.UseProgram(shaderProgram);

	// mouse move
	vertexLocation := gl.GetUniformLocation(shaderProgram, "iMove");
	gl.Uniform2f(vertexLocation, -cameraTranslation[0], cameraTranslation[1]);
	vertexLocation = gl.GetUniformLocation(shaderProgram, "iZoom");
	gl.Uniform1f(vertexLocation, f32(1 / zoom));
	vertexLocation = gl.GetUniformLocation(shaderProgram, "iTime");
	gl.Uniform1i(vertexLocation, i32(math.floor(currentTime)));

	gl.BindVertexArray(VAO);
	gl.DrawArrays(gl.TRIANGLE_STRIP, 0, 4);

	// fps counter
	nbFrames += 1;
	if (currentTime - lastTime >= 1)
	{ // If last prinf() was more than 1 sec ago
		// printf and reset timer
		fps = nbFrames;
		nbFrames = 0;
		lastTime += 1.0;
	}
}


whell := 0.0
rightClick := false
leftClick := false
wherePressed: Vec2 = {0, 0}
canDrag := true
mousePosition: Vec2 = {-100, -100}
cameraTranslation: Vec2 = {0, 0}
target: Vec2 = {0, 0}
zoom := 184.0


lastTime: f64
fps, nbFrames := 0, 0

reset :: proc "c" (window: glfw.WindowHandle)
{
	zoom := 184
	cameraTranslation = {0, 0}
	glfw.SetCursorPos(window, f64(screen_width) / 2, f64(screen_height) / 2)
}

resizeCallback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	screen_width = width
	screen_height = height
	gl.Viewport(0, 0, i32(screen_width), i32(screen_height))
	vertexLocation := gl.GetUniformLocation(shaderProgram, "iScreen")
	gl.Uniform2f(vertexLocation, f32(screen_width), f32(screen_height))
}

scrollCallback :: proc "c" (window: glfw.WindowHandle, xoffset, yoffset: f64)
{
	toZoom := zoom * (0.5 * yoffset + 1)
	if (toZoom > 0)
	{
		screen: Vec2 = {f32(screen_width / 2), f32(screen_height / 2)}
		cameraTranslation = mousePosition + cameraTranslation - screen
		glfw.SetCursorPos(window, f64(screen_width) / 2, f64(screen_height) / 2)
		cameraTranslation = cameraTranslation * f32(toZoom / zoom);
		zoom = toZoom
	}
}

mouseButtonCallback :: proc "c" (window: glfw.WindowHandle, button, action, mods: i32)
{
	if (button == glfw.MOUSE_BUTTON_LEFT && action == glfw.PRESS)
	{
		target = mousePosition;
		wherePressed = cameraTranslation;
		canDrag = true;
	}

	if (button == glfw.MOUSE_BUTTON_LEFT && action == glfw.RELEASE)
	{
		canDrag = false;
	}

	if (button == glfw.MOUSE_BUTTON_MIDDLE && action == glfw.PRESS)
	{
		reset(window);
	}
}

mouseCursorCallback :: proc "c" (window: glfw.WindowHandle, xpos, ypos: f64)
{
	x, y := glfw.GetCursorPos(window);
	mousePosition = Vec2{f32(x), f32(y)};

	if (canDrag && glfw.GetMouseButton(window, glfw.MOUSE_BUTTON_LEFT) != glfw.RELEASE)
	{
		cameraTranslation = target - mousePosition + wherePressed;
	}
}


main :: proc() {
    if !glfw.Init() {
        fmt.print("could not init glfw")
        return
    }

    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.OPENGL_DEBUG_CONTEXT, glfw.TRUE)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    window := glfw.CreateWindow(screen_width, screen_height, "Title", nil, nil)
    if window == nil {
        fmt.print("could not create window")
        return
    }

    glfw.SwapInterval(1)
    glfw.MakeContextCurrent(window)
	//gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);
	glfw.SetCursorPosCallback(window, mouseCursorCallback);
	glfw.SetMouseButtonCallback(window, mouseButtonCallback);
	glfw.SetScrollCallback(window, scrollCallback);
	glfw.SetWindowSizeCallback(window, resizeCallback);
    gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	init();
    
    for !glfw.WindowShouldClose(window) {
		//sprintf(title, "fps: %d, %s", fps, output);
		title := fmt.caprintf ("fps: %d", fps);
		// title := strings.concatenate({"fps: ", fps})
		glfw.SetWindowTitle(window, title);
		
		glfw.PollEvents();

		render();

        glfw.SwapBuffers(window);
    }

    glfw.DestroyWindow(window)
}