//
//  Renderer.swift
//  Example Shared
//
//  Created by Reza Ali on 8/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import MetalKit

import Forge
import Satin

class Renderer: Forge.Renderer {

    /// Loads a video and extracts frames in to MTLTexture instances
    var videoSource: VideoTextureSource!

    /// If true uses the video to texture the cube, otherwise a static texture will be shown
    /// NOTE: Video doesn't work in the simulator
    let useVideo = true

    lazy var texture: Texture? = {
        var texture: Texture?
        if let mtlTexture = Texture.load(
            context: self.context,
            named: "bricks",
            options: [.generateMipmaps: true]) {

            let samplerDescriptor = MTLSamplerDescriptor()
            samplerDescriptor.normalizedCoordinates = true
            samplerDescriptor.minFilter = .linear
            samplerDescriptor.magFilter = .linear
            samplerDescriptor.mipFilter = .linear
            if let sampler = context.device.makeSamplerState(descriptor: samplerDescriptor) {
                texture = Texture(mtlTexture: mtlTexture, samplerState: sampler)
            }
        }
        return texture
    }()

    lazy var mesh: Mesh = {
//        Mesh(geometry: BoxGeometry(), material: UVColorMaterial())
//         Mesh(geometry: BoxGeometry(), material: NormalColorMaterial())

        return Mesh(
            geometry: BoxGeometry(),
            material: BasicMaterial(color: simd_make_float4(1.0, 0.0, 0.0, 1.0), diffuse: texture)
        )
    }()
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(mesh)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: ArcballPerspectiveCamera = {
        let camera = ArcballPerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 9.0)
        camera.near = 0.001
        camera.far = 100.0
        return camera
    }()
    
    lazy var cameraController: ArcballCameraController = {
        ArcballCameraController(camera: camera, view: mtkView, defaultPosition: camera.position, defaultOrientation: camera.orientation)
    }()
    
    lazy var renderer: Satin.Renderer = {
        Satin.Renderer(context: context, scene: scene, camera: camera)
    }()
    
    required init?(metalKitView: MTKView) {
        super.init(metalKitView: metalKitView)
    }
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.autoResizeDrawable = false
        #if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            metalKitView.preferredFramesPerSecond = 120
        case .phone:
            metalKitView.preferredFramesPerSecond = 60
        case .unspecified:
            metalKitView.preferredFramesPerSecond = 60
        case .tv:
            metalKitView.preferredFramesPerSecond = 60
        case .carPlay:
            metalKitView.preferredFramesPerSecond = 60
        @unknown default:
            metalKitView.preferredFramesPerSecond = 60
        }
        #else
        metalKitView.preferredFramesPerSecond = 60
        #endif
    }
    
    override func setup() {
        //Setup things here

        let url = Bundle.main.url(forResource: "cubes-720p", withExtension: "mov")!
        videoSource = VideoTextureSource(context: context, videoUrl: url)
        videoSource.play(repeat: true)
    }
    
    override func update() {

        if useVideo, let texture = texture, let frame = videoSource.createTexture(hostTime: nil) {
            texture.update(frame)
        }

        cameraController.update()
        renderer.update()
    }
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
    }
}
