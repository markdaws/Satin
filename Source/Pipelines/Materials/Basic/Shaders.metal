fragment float4 basicFragment(VertexData in [[stage_in]],
                              constant BasicUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]])
{
    return uniforms.color;
}

fragment float4 basicDiffuseFragment(VertexData in [[stage_in]],
                                     texture2d<float, access::sample> diffuseTexture [[texture(0)]],
                                     sampler diffuseSampler [[sampler(0)]],
                                     constant BasicUniforms &uniforms [[buffer( FragmentBufferMaterialUniforms )]])
{
    return diffuseTexture.sample(diffuseSampler, in.uv).rgba;
}
