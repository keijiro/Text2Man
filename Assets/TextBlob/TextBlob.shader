Shader "TextBlob"
{
    Properties
    {
        _Intro("Intro", Float) = 0
        _Outro("Outro", Float) = 0
        _LocalTime("Local Time", Float) = 0
    }

    CGINCLUDE

    #include "Common.hlsl"
    #include "SimplexNoise3D.hlsl"

    float _Intro;
    float _Outro;
    float _LocalTime;

    struct Varyings
    {
        float4 position : SV_Position;
        float3 edge : TEXCOORD1;
    };

    void Vertex(
        uint vid : SV_VertexID,
        inout float4 position : POSITION
    )
    {
        uint seed = vid * 971;

        float3 rjitter = RandomVector(seed) * 0.5;
        float3 njitter = snoise_grad(float3(position.xy * 3, _LocalTime * 2)).xyz * 0.1;

        float intro = position.x / 2 + _Intro;
        float outro = position.x / 2 + _Outro;

        float3 p0 = njitter * 0.1;
        float3 p1 = position.xyz + rjitter;
        float3 p2 = position.xyz - njitter * 0.1;
        float3 p3 = njitter * 0.5;

        float t1 = smoothstep(0.0, 0.5, intro);
        float t2 = smoothstep(0.5, 1.0, intro);
        float t3 = smoothstep(0.0, 1.0, outro);

        position.xyz = lerp(lerp(lerp(p0, p1, t1), p2, t2), p3, t3);
    }

    Varyings VertexOutput(float3 wpos, half3 edge)
    {
        Varyings o;
        o.position = UnityObjectToClipPos(float4(wpos, 1));
        o.edge = edge;
        return o;
    }

    [maxvertexcount(3)]
    void Geometry(
        uint pid : SV_PrimitiveID,
        triangle float4 input[3] : POSITION,
        inout TriangleStream<Varyings> outStream
    )
    {
        float3 v1 = input[0];
        float3 v2 = input[1];
        float3 v3 = input[2];

        /*
        uint seed = pid * 837;
        float3 s1 = RandomVector(seed + 0) * 0.1;
        float3 s2 = RandomVector(seed + 2) * 0.1;
        float3 s3 = RandomVector(seed + 4) * 0.1;

        float intro = smoothstep(0, 1, center.x + center.y / 2 + _Intro);
        float outro = smoothstep(0, 1, center.x + center.y / 2 + _Outro);

        float3 jitter1 = snoise_grad(float3(v1.xy * 4 + 1, _LocalTime)).xyz * 0.02;
        float3 jitter2 = snoise_grad(float3(v2.xy * 4 + 1, _LocalTime)).xyz * 0.02;
        float3 jitter3 = snoise_grad(float3(v3.xy * 4 + 1, _LocalTime)).xyz * 0.02;

        v1 += RandomVector(pid * 10 + 0) * (1 - intro);
        v2 += RandomVector(pid * 10 + 3) * (1 - intro);
        v3 += RandomVector(pid * 10 + 6) * (1 - intro);

        v1 = lerp(0, v1 + jitter1, intro);
        v2 = lerp(0, v2 + jitter2, intro);
        v3 = lerp(0, v3 + jitter3, intro);
        */

        outStream.Append(VertexOutput(v1, half3(1, 0, 0)));
        outStream.Append(VertexOutput(v2, half3(0, 1, 0)));
        outStream.Append(VertexOutput(v3, half3(0, 0, 1)));
        outStream.RestartStrip();
    }

    half4 Fragment(Varyings input) : SV_Target
    {
        float3 bcc = input.edge;
        float3 fw = fwidth(bcc);
        float3 edge3 = min(smoothstep(fw / 2, fw,     bcc),
                           smoothstep(fw / 2, fw, 1 - bcc));
        float edge = 1 - min(min(edge3.x, edge3.y), edge3.z);

        return edge;
    }

    ENDCG

    SubShader
    {
        Pass
        {
            Cull Off ZWrite Off Blend One One
            CGPROGRAM
            #pragma vertex Vertex
            #pragma geometry Geometry
            #pragma fragment Fragment
            ENDCG
        }
    }
}
