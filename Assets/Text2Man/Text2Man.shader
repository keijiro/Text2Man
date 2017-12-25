Shader "TextBlob"
{
    Properties
    {
        _Radius("Radius", Float) = 1
        _Intro("Intro", Float) = 0
        _Outro("Outro", Float) = 0
        _LocalTime("Animation Time", Float) = 0
    }

    CGINCLUDE

    #include "Common.hlsl"
    #include "SimplexNoise3D.hlsl"

    float _Radius;
    float _Intro;
    float _Outro;
    float _LocalTime;

    float4 Vertex(uint vid : SV_VertexID, float4 position : POSITION) : SV_Position
    {
        float intro = +position.x / 2 + _Intro;
        float outro = -position.x / 2 - _Outro;

        float3 ncoord = position.xyz * 2 + float3(0, 0, _LocalTime * 2.3);

        float3 v_jitter = RandomVector(vid);
        float3 v_noise = snoise_grad(ncoord).xyz;

        float3 p0 = v_noise * _Radius;
        float3 p1 = position.xyz + v_jitter * 0.5;
        float3 p2 = position.xyz + v_noise * 0.02;

        float t_min = min(intro, outro);
        float t1 = smoothstep(0.0, 0.5, t_min);
        float t2 = smoothstep(0.5, 1.0, t_min);

        position.xyz = lerp(lerp(p0, p1, t1), p2, t2);

        return UnityObjectToClipPos(position);
    }

    half4 Fragment() : SV_Target
    {
        return 1;
    }

    ENDCG

    SubShader
    {
        Pass
        {
            Cull Off ZWrite Off Blend One One
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            ENDCG
        }
    }
}
