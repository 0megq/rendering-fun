package main

import "core:fmt"
import "core:strings"
import "core:time"
import gl "vendor:OpenGL"
import "vendor:glfw"

Vertex :: struct {
	pos: [3]f32,
}


main :: proc() {
	if !glfw.Init() {
		glfw.Terminate()
		return
	}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	window := glfw.CreateWindow(640, 480, "Hello World", nil, nil)
	if window == nil {
		return
	}
	defer glfw.DestroyWindow(window)

	glfw.MakeContextCurrent(window)

	gl.load_up_to(3, 3, glfw.gl_set_proc_address)
	if gl.GetError() != gl.NO_ERROR {
		return
	}

	gl.Viewport(0, 0, 640, 480)
	glfw.SetFramebufferSizeCallback(window, resize_callback)

	// vertex shader setup
	vertex_shader_source: cstring = strings.clone_to_cstring(
		`
		#version 330 core

		layout(location = 0) in vec3 aPos; // xyz

		uniform float uTime; // time in milliseconds

		void main()
		{
			float offset = 0.5 * sin(uTime);
			gl_Position = vec4(aPos.x + offset, aPos.y, aPos.z, 1.0); // this format
		}
	`,
	)
	defer delete(vertex_shader_source)

	vertex_shader: u32 = gl.CreateShader(gl.VERTEX_SHADER)

	gl.ShaderSource(vertex_shader, 1, &vertex_shader_source, nil) // shader object, number of strings, pointer to array of strings, and last one is nil (idk what it is)
	gl.CompileShader(vertex_shader)

	// check for shader compile errors
	success: i32
	info_log: [512]u8
	gl.GetShaderiv(vertex_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		gl.GetShaderInfoLog(vertex_shader, 512, nil, &info_log[0])
		fmt.printf("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n%s\n", info_log)
	}

	// fragment shader setup
	fragment_shader_source: cstring = strings.clone_to_cstring(
		`
		#version 330 core

		out vec4 FragColor;

		void main()
		{
			FragColor = vec4(1.0f, 0.1f, 0.2f, 1.0f);
		}
	`,
	)
	defer delete(fragment_shader_source)

	fragment_shader: u32 = gl.CreateShader(gl.FRAGMENT_SHADER)

	gl.ShaderSource(fragment_shader, 1, &fragment_shader_source, nil)
	gl.CompileShader(fragment_shader)

	// check for shader compile errors
	gl.GetShaderiv(fragment_shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		gl.GetShaderInfoLog(fragment_shader, 512, nil, &info_log[0])
		fmt.printf("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n%s\n", info_log)
	}

	// Creating the shader program and linking the vertex and fragment shaders
	shader_program: u32 = gl.CreateProgram()

	gl.AttachShader(shader_program, vertex_shader)
	gl.AttachShader(shader_program, fragment_shader)
	gl.LinkProgram(shader_program)

	gl.GetProgramiv(shader_program, gl.LINK_STATUS, &success)
	if success == 0 {
		gl.GetProgramInfoLog(shader_program, 512, nil, &info_log[0])
		fmt.printf("ERROR::SHADER::PROGRAM::LINKING_FAILED\n%s\n", info_log)
	}

	// we can delete the compiled shaders, we no longer need them
	gl.DeleteShader(vertex_shader)
	gl.DeleteShader(fragment_shader)


	verts: [4]Vertex = {
		{{0.5, 0.5, 0.0}},
		{{0.5, -0.5, 0.0}},
		{{-0.5, -0.5, 0.0}},
		{{-0.5, 0.5, 0.0}},
	}

	indices := [?]u32{0, 1, 3, 1, 2, 3}

	// an OpenGL object
	VBO, VAO, EBO: u32 // Vertex Buffer Object: stores a large number of vertices in the GPU's memory. Allows us to batch CPU -> GPU transfer
	// Vertex Array Object
	// stores:
	// calls to glEnableVertexAttribArray and disable
	// vertex attribute configs via glVertexAttribPointer
	// VBO's associatesed with vertex attributes by calls to glVertexAttribPointe
	gl.GenVertexArrays(1, &VAO)
	gl.GenBuffers(1, &VBO)
	gl.GenBuffers(1, &EBO)

	// bind VAO first, then bind and set vertex buffers, and configure their vertex attributes
	gl.BindVertexArray(VAO)

	// bind the buffer object we just created to the gl.ARRAY_BUFFER which is the buffer type of a vertex buffer object
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)

	// copy the vertex data into the buffer's memory
	gl.BufferData(gl.ARRAY_BUFFER, size_of(verts), &verts[0], gl.STATIC_DRAW)
	// gl.STREAM_DRAW: the data is set only once and used by the GPU at most a few times.
	// gl.STATIC_DRAW: the data is set only once and used many times.
	// gl.DYNAMIC_DRAW: the data is changed a lot and used many times.

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), &indices[0], gl.STATIC_DRAW)

	// Linking vertex attributes. This is where we specify what part of our input data goes to which vertex attribute in the vertex shader.

	// This function will tell OpenGL how it should interpret the vertex data (per vertex attribute)
	// 0 here corresponds to location = 0 of our vertex attribute in our vertex shader.
	// 3 corresponds to 3 in vec3. (I think)
	// type
	// if true this will assume we are inputting ints (not floats) and will normalize the value from 0 (-1 for signed value) to 1.
	// 0 is the offset of where the data begins. our data starts at the start of the array so this value is 0
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)

	// Now we enable the vertex attribute we just specified how it should be interpreted
	gl.EnableVertexAttribArray(0)

	// now unbind our VBO
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)

	// gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE) for a wireframe
	time_location := gl.GetUniformLocation(shader_program, "uTime")
	if time_location == -1 {
		fmt.println("Failed to find uniform location for 'uTime'")
		return
	}

	start_time := time.now()
	gl.ClearColor(0.2, 0.3, 0.3, 1.0)
	for !glfw.WindowShouldClose(window) {
		current_time := f32(time.duration_seconds(time.since(start_time)))
		// render
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// draw our first triangle
		gl.UseProgram(shader_program)
		gl.Uniform1f(time_location, current_time)

		gl.BindVertexArray(VAO) // seeing as we only have a single VAO there's no need to bind it every time, but we'll do so to keep things a bit more organized
		gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
		gl.BindVertexArray(0) // no need to unbind it every time 

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
	gl.DeleteVertexArrays(1, &VAO)
	gl.DeleteBuffers(1, &EBO)
	gl.DeleteBuffers(1, &VBO)
	gl.DeleteProgram(shader_program)

	return
}

resize_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
