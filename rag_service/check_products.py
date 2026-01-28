"""
Script để kiểm tra products trong vector store và database
"""
import asyncio
import sys
import os
from pathlib import Path

# Set UTF-8 encoding for Windows
if sys.platform == 'win32':
    os.environ['PYTHONIOENCODING'] = 'utf-8'

sys.path.insert(0, str(Path(__file__).parent))

from app.api.deps import get_image_vector_store
import pyodbc
from app.core.settings import Settings

async def check_products():
    """Kiểm tra products trong vector store và database"""
    print("Dang kiem tra products...")
    
    # 1. Lấy products từ vector store
    vector_store = get_image_vector_store()
    results = await asyncio.to_thread(
        vector_store.collection.get,
        where={"content_type": "product"}
    )
    
    ids = results.get('ids', [])
    metadatas = results.get('metadatas', [])
    
    print(f"\nTong so products trong vector store: {len(ids)}")
    
    # 2. Kiểm tra products có "thịt bò"
    thit_bo_products = []
    for i, metadata in enumerate(metadatas):
        product_name = metadata.get('product_name') or metadata.get('file_name', '')
        description = metadata.get('description', '')
        product_id = metadata.get('product_id') or metadata.get('file_id', '')
        
        if 'thit bo' in str(product_name).lower().replace('ị', 'i').replace('ò', 'o') or 'thit bo' in str(description).lower().replace('ị', 'i').replace('ò', 'o'):
            thit_bo_products.append({
                'id': product_id,
                'name': product_name,
                'description': description[:50]
            })
    
    print(f"\nProducts co 'thit bo': {len(thit_bo_products)}")
    for p in thit_bo_products[:5]:
        try:
            print(f"  - {p['name']} (ID: {p['id']})")
        except:
            print(f"  - Product (ID: {p['id']})")
    
    # 3. Kiểm tra products có tồn tại trong database không
    print(f"\nDang kiem tra products trong database...")
    
    conn_str = Settings.DATABASE_CONNECTION_STRING
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
    
    conn = None
    for driver_name in ["ODBC Driver 18 for SQL Server", "ODBC Driver 17 for SQL Server", "SQL Server Native Client 11.0"]:
        try:
            test_conn_str = conn_str.replace("{ODBC Driver 18 for SQL Server}", f"{{{driver_name}}}")
            test_conn_str = test_conn_str.replace("{ODBC Driver 17 for SQL Server}", f"{{{driver_name}}}")
            if driver_name not in test_conn_str:
                import re
                test_conn_str = re.sub(r'DRIVER=\{[^}]+\}', f'DRIVER={{{driver_name}}}', test_conn_str, count=1)
            conn = pyodbc.connect(test_conn_str)
            print(f"Ket noi database thanh cong voi driver: {driver_name}")
            break
        except Exception as e:
            continue
    
    if conn:
        cursor = conn.cursor()
        
        # Kiểm tra 5 products đầu tiên
        found = 0
        not_found = 0
        with_images = 0
        
        for i in range(min(5, len(ids))):
            product_id = metadatas[i].get('product_id') or metadatas[i].get('file_id', '')
            if not product_id and ids[i]:
                chunk_id = ids[i]
                if '-chunk-' in chunk_id:
                    product_id = chunk_id.split('-chunk-')[0]
            
            if product_id:
                query = "SELECT Anh FROM SanPham WHERE MaSanPham = ? AND (IsDeleted = 0 OR IsDeleted IS NULL)"
                cursor.execute(query, product_id)
                row = cursor.fetchone()
                
                if row:
                    found += 1
                    if row[0]:
                        with_images += 1
                        print(f"  OK {product_id}: Ton tai, co anh: {row[0]}")
                    else:
                        print(f"  WARN {product_id}: Ton tai, khong co anh")
                else:
                    not_found += 1
                    print(f"  ERROR {product_id}: Khong ton tai trong database")
        
        cursor.close()
        conn.close()
        
        print(f"\nKet qua kiem tra:")
        print(f"  Ton tai: {found}")
        print(f"  Khong ton tai: {not_found}")
        print(f"  Co anh: {with_images}")

if __name__ == "__main__":
    asyncio.run(check_products())

