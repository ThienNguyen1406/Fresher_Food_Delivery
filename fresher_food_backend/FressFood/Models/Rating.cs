using System.Text.Json.Serialization;

namespace FressFood.Models
{
    public class Rating
    {
        [JsonPropertyName("maSanPham")]
        public string MaSanPham { get; set; } = string.Empty;
        
        [JsonPropertyName("maTaiKhoan")]
        public string MaTaiKhoan { get; set; } = string.Empty;
        
        [JsonPropertyName("noiDung")]
        public string? NoiDung { get; set; }
        
        [JsonPropertyName("soSao")]
        public int SoSao { get; set; }
    }
}
