package main

import "core:fmt"
import gl "vendor:OpenGL"
import "vendor:glfw"


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

	gl.ClearColor(0.2, 0.3, 0.3, 1.0)


	verts: [9]f32 = {-0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.5, 0.5, 0.0}

	// an OpenGL object
	VBO: u32 // Vertex Buffer Object: stores a large number of vertices in the GPU's memory. Allows us to batch CPU -> GPU transfer
	gl.GenBuffers(1, &VBO)

	// bind the buffer object we just created to the gl.ARRAY_BUFFER which is the buffer type of a vertex buffer object
	gl.BindBuffer(gl.ARRAY_BUFFER, VBO)

	// copy the vertex data into the buffer's memory
	gl.BufferData(gl.ARRAY_BUFFER, size_of(verts), &verts[0], gl.STATIC_DRAW)
	// gl.STREAM_DRAW: the data is set only once and used by the GPU at most a few times.
	// gl.STATIC_DRAW: the data is set only once and used many times.
	// gl.DYNAMIC_DRAW: the data is changed a lot and used many times.


	for !glfw.WindowShouldClose(window) {
		gl.Clear(gl.COLOR_BUFFER_BIT)
		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
	return
}

resize_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	gl.Viewport(0, 0, width, height)
}
