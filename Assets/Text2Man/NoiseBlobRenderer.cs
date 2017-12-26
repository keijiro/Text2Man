using UnityEngine;
using UnityEngine.Timeline;

namespace Text2Man
{
    [ExecuteInEditMode]
    class NoiseBlobRenderer : MonoBehaviour, ITimeControl
    {
        #region Editable properties

        [SerializeField] Mesh _mesh;

        [SerializeField, ColorUsage(false, true, 0, 8, 0.125f, 3)]
        Color _color = Color.white;

        [SerializeField] float _radius = 0.1f;

        [SerializeField, Range(-1, 1)] float _parameter = 0;

        #endregion

        #region Internal resources

        [SerializeField, HideInInspector] Shader _shader;

        #endregion

        #region Private variables and properties

        Material _material;
        float _controlTime = -1;

        float LocalTime {
            get {
                if (_controlTime < 0)
                    return Application.isPlaying ? Time.time : 0;
                else
                    return _controlTime;
            }
        }

        float MeshExtent {
            get {
                if (_mesh == null) return 0;
                var bounds = _mesh.bounds;
                return Mathf.Max(-bounds.min.x, bounds.max.x);
            }
        }

        #endregion

        #region ITimeControl implementation

        public void OnControlTimeStart()
        {
        }

        public void OnControlTimeStop()
        {
            _controlTime = -1;
        }

        public void SetTime(double time)
        {
            _controlTime = (float)time;
        }

        #endregion

        #region MonoBehaviour implementation

        void OnDestroy()
        {
            if (_material != null)
            {
                if (Application.isPlaying)
                    Destroy(_material);
                else
                    DestroyImmediate(_material);
            }
        }

        void LateUpdate()
        {
            if (_mesh == null) return;

            if (_material == null)
            {
                _material = new Material(_shader);
                _material.hideFlags = HideFlags.DontSave;
            }

            var p0 = MeshExtent / 2;
            var p1 = p0 + 1;

            if (_parameter >= 0)
            {
                _material.SetFloat("_Intro", p1);
                _material.SetFloat("_Outro", Mathf.Lerp(-p1, p0, _parameter));
            }
            else
            {
                _material.SetFloat("_Intro", Mathf.Lerp(p1, -p0, -_parameter));
                _material.SetFloat("_Outro", -p1);
            }

            _material.SetColor("_Color", _color);
            _material.SetFloat("_Radius", _radius);
            _material.SetFloat("_LocalTime", LocalTime);

            Graphics.DrawMesh(
                _mesh, transform.localToWorldMatrix,
                _material, gameObject.layer
            );
        }

        #endregion
    }
}
