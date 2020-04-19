//
//  BasicMaterial.swift
//  Satin
//
//  Created by Reza Ali on 9/25/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Metal
import simd

open class BasicMaterial: Material {
    var color = Float4Parameter("color")
    private var diffuse: Texture?

    lazy var parameters: ParameterGroup = {
        let params = ParameterGroup("BasicUniforms")
        params.append(color)
        return params
    }()

    var uniforms: UniformBuffer?

    public init(color: simd_float4, diffuse: Texture? = nil) {
        super.init()
        self.color.value = color
        self.diffuse = diffuse
    }

    override func setup() {
        setupPipeline()
        setupUniforms()
    }

    override func update() {
        uniforms?.update()
        super.update()
    }

    func setupPipeline() {
        BasicPipeline.setup(context: context, parameters: parameters, hasDiffuse: diffuse != nil)
        if let pipeline = BasicPipeline.shared.pipeline {
            self.pipeline = pipeline
        }
    }

    func setupUniforms() {
        guard let context = self.context else { return }
        uniforms = UniformBuffer(context: context, parameters: parameters)
    }

    open override func bind(_ renderEncoder: MTLRenderCommandEncoder) {
        if let uniforms = self.uniforms {
            renderEncoder.setFragmentBuffer(uniforms.buffer, offset: uniforms.offset, index: FragmentBufferIndex.MaterialUniforms.rawValue)
        }

        if let diffuse = self.diffuse {
            renderEncoder.setFragmentTexture(diffuse.mtlTexture, index: FragmentTextureIndex.Custom0.rawValue)
            renderEncoder.setFragmentSamplerState(diffuse.samplerState, index: FragmentSamplerIndex.Custom0.rawValue)
        }

        super.bind(renderEncoder)
    }
}

class BasicPipeline {
    static let shared = BasicPipeline()
    private static var sharedPipeline: MTLRenderPipelineState?
    let pipeline: MTLRenderPipelineState?

    class func setup(context: Context?, parameters: ParameterGroup, hasDiffuse: Bool) {
        guard BasicPipeline.sharedPipeline == nil, let context = context, let pipelinesPath = getPipelinesPath() else { return }
        do {
            if let source = try makePipelineSource(pipelinesPath, "Basic", parameters) {
                let library = try context.device.makeLibrary(source: source, options: .none)
                let pipeline = try makeAlphaRenderPipeline(
                    library: library,
                    vertex: "vert",
                    fragment: hasDiffuse ? "basicDiffuseFragment" : "basicFragment",
                    label: "Basic",
                    context: context)

                BasicPipeline.sharedPipeline = pipeline
            }
        }
        catch {
            print(error)
            return
        }
    }

    init() {
        pipeline = BasicPipeline.sharedPipeline
    }
}
