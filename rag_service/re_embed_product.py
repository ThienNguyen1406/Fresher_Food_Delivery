"""
Script để re-embed một product cụ thể hoặc tất cả products với combined embedding mới
"""
import asyncio
import sys
import os
from pathlib import Path
import httpx
from urllib.parse import quote

# Set UTF-8 encoding for Windows
if sys.platform == 'win32':
    os.environ['PYTHONIOENCODING'] = 'utf-8'
    sys.stdout.reconfigure(encoding='utf-8')

sys.path.insert(0, str(Path(__file__).parent))

from app.api.deps import get_image_vector_store, get_product_ingest_pipeline
from app.core.settings import Settings
import pyodbc

async def check_product_in_vector_store(product_id: str):
    """Kiểm tra xem product đã có trong vector store chưa"""
    vector_store = get_image_vector_store()
    # ChromaDB requires $and for multiple conditions
    results = await asyncio.to_thread(
        vector_store.collection.get,
        where={"$and": [{"product_id": product_id}, {"content_type": "product"}]}
    )
    
    ids = results.get('ids', [])
    return len(ids) > 0

async def get_product_from_db(product_id: str):
    """Lấy product từ database"""
    conn_str = Settings.DATABASE_CONNECTION_STRING
    
    # Convert to ODBC format
    if "DRIVER=" not in conn_str.upper():
        params = {}
        parts = [p.strip() for p in conn_str.split(';') if p.strip()]
        for part in parts:
            if '=' in part:
                key, value = part.split('=', 1)
                key = key.strip().lower()
                value = value.strip()
                params[key] = value
        
        server = params.get('server', '')
        database = params.get('database', '')
        user_id = params.get('user id', params.get('uid', ''))
        password = params.get('password', params.get('pwd', ''))
        trust_cert = params.get('trustservercertificate', 'True').lower() == 'true'
        
        driver = "ODBC Driver 18 for SQL Server"
        odbc_conn_str = f"DRIVER={{{driver}}};SERVER={server};DATABASE={database};"
        if user_id:
            odbc_conn_str += f"UID={user_id};PWD={password};"
        if trust_cert:
            odbc_conn_str += "TrustServerCertificate=yes;"
        conn_str = odbc_conn_str
    
    # Try to connect
    conn = None
    for driver_name in ["ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server", "SQL Server Native Client 11.0"]:
        try:
            test_conn_str = conn_str.replace("{ODBC Driver 18 for SQL Server}", f"{{{driver_name}}}")
            test_conn_str = test_conn_str.replace("{ODBC Driver 17 for SQL Server}", f"{{{driver_name}}}")
            if driver_name not in test_conn_str:
                import re
                test_conn_str = re.sub(r'DRIVER=\{[^}]+\}', f'DRIVER={{{driver_name}}}', test_conn_str, count=1)
            conn = pyodbc.connect(test_conn_str)
            break
        except:
            continue
    
    if not conn:
        print("❌ Không thể kết nối database")
        return None
    
    try:
        cursor = conn.cursor()
        query = """
            SELECT s.MaSanPham, s.TenSanPham, s.MoTa, s.Anh, s.GiaBan, s.MaDanhMuc, 
                   dm.TenDanhMuc, s.DonViTinh, s.XuatXu
            FROM SanPham s
            LEFT JOIN DanhMuc dm ON s.MaDanhMuc = dm.MaDanhMuc
            WHERE s.MaSanPham = ? AND (s.IsDeleted = 0 OR s.IsDeleted IS NULL)
        """
        cursor.execute(query, product_id)
        row = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if row:
            return {
                'product_id': row[0],
                'product_name': row[1],
                'description': row[2] or '',
                'image_filename': row[3] or '',
                'price': float(row[4]) if row[4] else 0.0,
                'category_id': row[5] if row[5] else '',  # Fix: row[5] is category_id, not row[4]
                'category_name': row[6] or '',
                'unit': row[7] or '',
                'origin': row[8] or ''
            }
        return None
    except Exception as e:
        print(f"❌ Lỗi khi query database: {e}")
        if conn:
            conn.close()
        return None

async def download_image(image_filename: str) -> bytes:
    """Download ảnh từ backend"""
    base_url = os.getenv("APP_BASE_URL", "https://localhost:7240")
    encoded_filename = quote(image_filename, safe='')
    image_url = f"{base_url}/images/products/{encoded_filename}"
    
    try:
        async with httpx.AsyncClient(verify=False, timeout=30.0) as client:
            response = await client.get(image_url)
            if response.status_code == 200:
                return response.content
            else:
                print(f"⚠️  Không thể download ảnh: {response.status_code}")
                return None
    except Exception as e:
        print(f"⚠️  Lỗi khi download ảnh: {e}")
        return None

async def embed_product(product_id: str, force_reembed: bool = False):
    """Embed một product cụ thể"""
    print(f"\n{'='*60}")
    print(f"🔍 Đang xử lý product: {product_id}")
    print(f"{'='*60}")
    
    # 1. Kiểm tra product trong vector store
    is_embedded = await check_product_in_vector_store(product_id)
    if is_embedded and not force_reembed:
        print(f"✅ Product {product_id} đã được embed")
        return
    
    # 2. Lấy product từ database
    print(f"📥 Đang lấy product từ database...")
    product = await get_product_from_db(product_id)
    if not product:
        print(f"❌ Không tìm thấy product {product_id} trong database")
        return
    
    print(f"✅ Tìm thấy product: {product['product_name']}")
    print(f"   - Category: {product['category_name']} ({product['category_id']})")
    print(f"   - Description: {product['description'][:50]}...")
    
    # 3. Download ảnh nếu có
    image_bytes = None
    if product['image_filename']:
        print(f"📷 Đang download ảnh: {product['image_filename']}")
        image_bytes = await download_image(product['image_filename'])
        if image_bytes:
            print(f"✅ Đã download ảnh: {len(image_bytes)} bytes")
        else:
            print(f"⚠️  Không thể download ảnh")
    
    # 4. Embed product
    print(f"🔄 Đang embed product với combined embedding (70% text CLIP + 30% image)...")
    try:
        pipeline = get_product_ingest_pipeline()
        
        product_data = {
            'product_id': product['product_id'],
            'product_name': product['product_name'],
            'description': product['description'],
            'category_id': product['category_id'],
            'category_name': product['category_name'],
            'price': product['price'],
            'unit': product['unit'],
            'origin': product['origin'],
            'image_filename': product['image_filename']
        }
        
        result_id = await pipeline.process_and_store(
            product_data,
            image_bytes,
            product_id=product['product_id']
        )
        
        print(f"✅ Đã embed product thành công: {result_id}")
    except Exception as e:
        print(f"❌ Lỗi khi embed product: {e}")
        import traceback
        traceback.print_exc()

async def main():
    """Main function"""
    print("🚀 Script re-embed products với combined embedding mới")
    print("="*60)
    
    # Re-embed product "Thịt bò"
    await embed_product("SP487277", force_reembed=True)
    
    print("\n" + "="*60)
    print("✅ Hoàn thành!")
    print("="*60)

if __name__ == "__main__":
    asyncio.run(main())

