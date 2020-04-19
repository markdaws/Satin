//
//  Texture.swift
//  Satin
//
//  Created by Mark Dawson on 4/19/20.
//

import Metal
import MetalKit

public final class Texture {

  var mtlTexture: MTLTexture
  let samplerState: MTLSamplerState

  public init(mtlTexture: MTLTexture, samplerState: MTLSamplerState) {
    self.mtlTexture = mtlTexture
    self.samplerState = samplerState
  }

  public func update(_ texture: MTLTexture) {
    mtlTexture = texture
  }

  public static func load(context: Context, named: String, options: [MTKTextureLoader.Option: Any]?) -> MTLTexture? {
    let loader = MTKTextureLoader(device: context.device)
    return try? loader.newTexture(name: named, scaleFactor: 1.0, bundle: nil, options: options)
  }
}
