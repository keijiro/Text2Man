Shader "TextBlob"
{
    Properties
    {
        _Color("Color", Color) = (1, 1, 1, 1)
        _Radius("Radius", Float) = 1
        _Intro("Intro", Float) = 0
        _Outro("Outro", Float) = 0
        _LocalTime("Animation Time", Float) = 0
    }

    CGINCLUDE

    #include "UnityCG.cginc"
    #include "SimplexNoise3D.hlsl"

    half4 _Color;
    float _Radius;
    float _Intro;
    float _Outro;
    float _LocalTime;

    // Hash function from H. Schechter & R. Bridson, goo.gl/RXiKaH
    uint Hash(uint s)
    {
        s ^= 2747636419u;
        s *= 2654435769u;
        s ^= s >> 16;
        s *= 2654435769u;
        s ^= s >> 16;
        s *= 2654435769u;
        return s;
    }

    float Random(uint seed)
    {
        return float(Hash(seed)) / 4294967295.0; // 2^32-1
    }

    // Uniformaly distributed points on a unit sphere
    // http://mathworld.wolfram.com/SpherePointPicking.html
    float3 RandomUnitVector(uint seed)
    {
        float PI2 = 6.28318530718;
        float z = 1 - 2 * Random(seed);
        float xy = sqrt(1.0 - z * z);
        float sn, cs;
        sincos(PI2 * Random(seed + 1), sn, cs);
        return float3(sn * xy, cs * xy, z);
    }

    // Uniformaly distributed points inside a unit sphere
    float3 RandomVector(uint seed)
    {
        return RandomUnitVector(seed) * sqrt(Random(seed + 2));
    }

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
        return _Color;
    }

    ENDCG

    SubShader
    {
        Tags { "Queue"="Transparent" }
        Pass
        {
            Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Fragment
            ENDCG
        }
    }
}
