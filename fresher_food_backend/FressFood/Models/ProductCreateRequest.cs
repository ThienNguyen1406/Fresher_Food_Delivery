namespace FressFood.Models
{
    public class ProductCreateRequest
    {
        public string TenSanPham { get; set; }
        public string MoTa { get; set; }
        public decimal GiaBan { get; set; }
        public IFormFile Anh { get; set; }
        public int SoLuongTon { get; set; }
        public string XuatXu { get; set; }
        public string DonViTinh { get; set; }
        public string MaDanhMuc { get; set; }
    }
}
