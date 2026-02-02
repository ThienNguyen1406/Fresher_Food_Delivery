# 🏗️ Fresher Food Delivery - System Architecture Diagrams

Tài liệu mô tả kiến trúc toàn bộ hệ thống bằng Mermaid diagrams.

---

## 1. 📐 System Architecture Overview

```mermaid
graph TB
    subgraph "Client Layer"
        A[Flutter Mobile App<br/>User & Admin Interfaces]
    end
    
    subgraph "API Gateway Layer"
        B[ASP.NET Core Backend<br/>REST API - Port 5000/5001]
    end
    
    subgraph "Service Layer"
        C[Python RAG Service<br/>FastAPI - Port 8000]
    end
    
    subgraph "Data Layer"
        D[(SQL Server Database<br/>FressFood.mdf)]
        E[(ChromaDB Vector Store<br/>Product Embeddings)]
    end
    
    subgraph "External Services"
        F[OpenAI API<br/>GPT-4 & Embeddings]
        G[Stripe API<br/>Payment Processing]
        H[Firebase<br/>Auth, Messaging, Storage]
    end
    
    A -->|HTTP/REST| B
    B -->|SQL Queries| D
    B -->|HTTP| C
    B -->|HTTP| G
    B -->|HTTP| H
    C -->|Vector Search| E
    C -->|API Calls| F
    C -->|SQL Queries| D
    H -->|Push Notifications| A
    G -->|Payment Webhooks| B
    
    style A fill:#4CAF50,stroke:#2E7D32,color:#fff
    style B fill:#2196F3,stroke:#1565C0,color:#fff
    style C fill:#FF9800,stroke:#E65100,color:#fff
    style D fill:#9C27B0,stroke:#6A1B9A,color:#fff
    style E fill:#00BCD4,stroke:#00838F,color:#fff
    style F fill:#673AB7,stroke:#4527A0,color:#fff
    style G fill:#009688,stroke:#00695C,color:#fff
    style H fill:#FF5722,stroke:#BF360C,color:#fff
```

---

## 2. 🔄 User Flow - Order Processing

```mermaid
sequenceDiagram
    participant U as User (Flutter App)
    participant B as Backend API
    participant DB as SQL Server
    participant S as Stripe API
    participant F as Firebase
    
    U->>B: 1. Login/Register
    B->>DB: Authenticate User
    DB-->>B: User Data
    B-->>U: JWT Token
    
    U->>B: 2. Browse Products
    B->>DB: Get Products
    DB-->>B: Product List
    B-->>U: Display Products
    
    U->>B: 3. Add to Cart
    B->>DB: Update Cart
    DB-->>B: Cart Updated
    B-->>U: Cart Confirmation
    
    U->>B: 4. Apply Coupon
    B->>DB: Validate Coupon
    DB-->>B: Coupon Details
    B-->>U: Discount Applied
    
    U->>B: 5. Place Order
    B->>DB: Create Order
    DB-->>B: Order Created
    B->>S: 6. Create Payment Intent
    S-->>B: Payment Intent ID
    B-->>U: Payment Details
    
    U->>S: 7. Process Payment
    S-->>B: Payment Webhook
    B->>DB: Update Order Status
    B->>F: 8. Send Notification
    F-->>U: Push Notification
    B-->>U: Order Confirmation
```

---

## 3. 🤖 AI Chat Flow with RAG

```mermaid
sequenceDiagram
    participant U as User (Flutter App)
    participant B as Backend API
    participant R as RAG Service
    participant V as Vector Store (ChromaDB)
    participant O as OpenAI API
    participant DB as SQL Server
    
    U->>B: 1. Send Message/Image
    B->>R: 2. Forward Query
    
    alt Text Query
        R->>R: 3a. Create Text Embedding
        R->>V: 3b. Vector Search
        V-->>R: Similar Products
    else Image Query
        R->>R: 3c. Create Image Embedding (CLIP)
        R->>V: 3d. Image Vector Search
        V-->>R: Similar Products
        
        alt Low Similarity (< 0.6)
            R->>O: 3e. Vision Caption (GPT-4V)
            O-->>R: Image Description
            R->>R: 3f. Hybrid Embedding
            R->>V: 3g. Re-search with Caption
            V-->>R: Better Results
        end
    end
    
    R->>DB: 4. Fetch Product Details
    DB-->>R: Product Data
    
    R->>O: 5. Generate Response (GPT-4)
    Note over R,O: Context: Product Info + User Query
    O-->>R: AI Response
    
    alt Function Calling Required
        R->>DB: 6. Execute Function (e.g., getCustomerOrders)
        DB-->>R: Function Result
        R->>O: 7. Regenerate with Function Result
        O-->>R: Final Response
    end
    
    R-->>B: 8. Return Response
    B->>DB: 9. Save Message
    B-->>U: 10. Display Response
```

---

## 4. 🗄️ Database Schema

```mermaid
erDiagram
    NguoiDung ||--o{ DonHang : places
    NguoiDung ||--o{ GioHang : has
    NguoiDung ||--o{ YeuThich : has
    NguoiDung ||--o{ Chat : creates
    NguoiDung ||--o{ DanhGia : writes
    
    DonHang ||--|{ ChiTietDonHang : contains
    DonHang }o--|| KhuyenMai : uses
    
    ChiTietDonHang }o--|| SanPham : references
    GioHang }o--|| SanPham : contains
    YeuThich }o--|| SanPham : contains
    DanhGia }o--|| SanPham : rates
    
    SanPham }o--|| DanhMuc : belongs_to
    SanPham ||--o{ TruyXuatNguonGoc : has
    
    Chat ||--o{ TinNhan : contains
    
    NguoiDung {
        int MaTaiKhoan PK
        string TenDangNhap
        string Email
        string MatKhau
        string VaiTro
        string HoTen
        string SoDienThoai
        string DiaChi
    }
    
    SanPham {
        int MaSanPham PK
        string TenSanPham
        string MoTa
        decimal GiaBan
        string DonViTinh
        string Anh
        int MaDanhMuc FK
        int SoLuongTon
    }
    
    DanhMuc {
        int MaDanhMuc PK
        string TenDanhMuc
        string MoTa
    }
    
    DonHang {
        int MaDonHang PK
        int MaTaiKhoan FK
        datetime NgayDat
        string TrangThai
        decimal TongTien
        int MaKhuyenMai FK
    }
    
    ChiTietDonHang {
        int MaChiTietDonHang PK
        int MaDonHang FK
        int MaSanPham FK
        int SoLuong
        decimal GiaBan
    }
    
    GioHang {
        int MaGioHang PK
        int MaTaiKhoan FK
        int MaSanPham FK
        int SoLuong
    }
    
    Chat {
        int MaChat PK
        int MaTaiKhoan FK
        string TieuDe
        datetime NgayTao
    }
    
    TinNhan {
        int MaTinNhan PK
        int MaChat FK
        int MaNguoiGui FK
        string LoaiNguoiGui
        string NoiDung
        datetime NgayGui
    }
    
    KhuyenMai {
        int MaKhuyenMai PK
        string MaGiamGia
        decimal PhanTramGiam
        datetime NgayBatDau
        datetime NgayKetThuc
    }
```

---

## 5. 📱 Flutter App Structure

```mermaid
graph TD
    A[main.dart] --> B[App Entry Point]
    B --> C[Theme Provider]
    B --> D[Language Provider]
    B --> E[Main Screen]
    
    E --> F[User Role]
    E --> G[Admin Role]
    
    F --> F1[Home Page]
    F --> F2[Cart Page]
    F --> F3[Chat List]
    F --> F4[Favorite Page]
    F --> F5[Account Page]
    
    F3 --> F3A[Chat Detail Page]
    F3A --> F3B[Message List]
    F3A --> F3C[Message Input]
    F3A --> F3D[Product Search]
    
    G --> G1[Admin Dashboard]
    G --> G2[Product Management]
    G --> G3[Order Management]
    G --> G4[Statistics]
    G --> G5[Chat Management]
    G --> G6[Promotion Management]
    
    H[Services Layer] --> H1[User API]
    H --> H2[Product API]
    H --> H3[Cart API]
    H --> H4[Order API]
    H --> H5[Chat API]
    H --> H6[RAG API]
    
    F1 --> H
    F2 --> H
    F3A --> H
    G1 --> H
    
    I[Models] --> I1[User]
    I --> I2[Product]
    I --> I3[Order]
    I --> I4[Chat]
    I --> I5[Message]
    
    H --> I
    
    style A fill:#4CAF50,stroke:#2E7D32,color:#fff
    style F fill:#2196F3,stroke:#1565C0,color:#fff
    style G fill:#FF9800,stroke:#E65100,color:#fff
    style H fill:#9C27B0,stroke:#6A1B9A,color:#fff
    style I fill:#00BCD4,stroke:#00838F,color:#fff
```

---

## 6. 🔧 Backend API Structure

```mermaid
graph TD
    A[Program.cs] --> B[Startup Configuration]
    B --> C[Controllers]
    B --> D[Services]
    B --> E[Models]
    B --> F[Database Context]
    
    C --> C1[UserController]
    C --> C2[ProductController]
    C --> C3[CartController]
    C --> C4[OrderController]
    C --> C5[ChatController]
    C --> C6[CouponController]
    C --> C7[StripeController]
    
    D --> D1[UserService]
    D --> D2[ProductService]
    D --> D3[OrderService]
    D --> D4[ChatbotService]
    D --> D5[OpenAIService]
    D --> D6[PythonRAGService]
    D --> D7[EmailService]
    D --> D8[FunctionHandlerService]
    
    C1 --> D1
    C2 --> D2
    C3 --> D2
    C4 --> D3
    C5 --> D4
    C5 --> D5
    C5 --> D6
    C7 --> D3
    
    D --> F
    F --> G[(SQL Server)]
    
    D6 --> H[Python RAG Service]
    D5 --> I[OpenAI API]
    
    style A fill:#2196F3,stroke:#1565C0,color:#fff
    style C fill:#4CAF50,stroke:#2E7D32,color:#fff
    style D fill:#FF9800,stroke:#E65100,color:#fff
    style G fill:#9C27B0,stroke:#6A1B9A,color:#fff
    style H fill:#FF5722,stroke:#BF360C,color:#fff
    style I fill:#673AB7,stroke:#4527A0,color:#fff
```

---

## 7. 🐍 RAG Service Architecture

```mermaid
graph TB
    subgraph "API Layer"
        A1[FastAPI Main]
        A2[Product Routes]
        A3[Search Routes]
        A4[Chat Routes]
    end
    
    subgraph "Core Layer"
        C1[Search Pipeline]
        C2[Product Ingest Pipeline]
        C3[Chat Pipeline]
        C4[Hybrid Ranker]
        C5[Embedding Cache]
    end
    
    subgraph "Domain Layer"
        D1[Product Model]
        D2[Embedding Model]
        D3[Search Model]
        D4[LLM Interface]
        D5[Vector Store Interface]
    end
    
    subgraph "Infrastructure Layer"
        I1[SQL Repository]
        I2[ChromaDB Vector Store]
        I3[Image Vector Store]
        I4[OpenAI LLM]
        I5[Embedding Service]
        I6[CLIP Model]
    end
    
    subgraph "Services Layer"
        S1[Product Service]
        S2[Search Service]
        S3[Chat Service]
    end
    
    A1 --> A2
    A1 --> A3
    A1 --> A4
    
    A2 --> S1
    A3 --> S2
    A4 --> S3
    
    S1 --> C2
    S2 --> C1
    S3 --> C3
    
    C1 --> C4
    C1 --> C5
    C2 --> C5
    C3 --> C4
    
    C1 --> D2
    C2 --> D1
    C3 --> D3
    
    D4 --> I4
    D5 --> I2
    D5 --> I3
    
    I1 --> J[(SQL Server)]
    I2 --> K[(ChromaDB)]
    I3 --> K
    I4 --> L[OpenAI API]
    I5 --> L
    I6 --> M[CLIP Model]
    
    S1 --> I1
    S2 --> I2
    S2 --> I3
    S2 --> I6
    S3 --> I4
    S3 --> I5
    
    style A1 fill:#FF5722,stroke:#BF360C,color:#fff
    style C1 fill:#FF9800,stroke:#E65100,color:#fff
    style D1 fill:#2196F3,stroke:#1565C0,color:#fff
    style I1 fill:#4CAF50,stroke:#2E7D32,color:#fff
    style S1 fill:#9C27B0,stroke:#6A1B9A,color:#fff
    style J fill:#673AB7,stroke:#4527A0,color:#fff
    style K fill:#00BCD4,stroke:#00838F,color:#fff
    style L fill:#795548,stroke:#5D4037,color:#fff
```

---

## 8. 🔍 Product Search Flow

```mermaid
flowchart TD
    Start([User Search Query]) --> Type{Query Type?}
    
    Type -->|Text| TextSearch[Text Search]
    Type -->|Image| ImageSearch[Image Search]
    Type -->|Chat| ChatSearch[Chat Search]
    
    TextSearch --> T1[Extract Keywords]
    T1 --> T2{Exact Match?}
    T2 -->|Yes| T3[SQL Exact Search]
    T2 -->|No| T4[CLIP Text Embedding]
    T4 --> T5[Vector Search]
    T3 --> T6[Merge Results]
    T5 --> T6
    T6 --> T7[Rank & Filter]
    T7 --> End([Return Products])
    
    ImageSearch --> I1[CLIP Image Embedding]
    I1 --> I2[Vector Search]
    I2 --> I3{Similarity >= 0.6?}
    I3 -->|Yes| I4[Return Results]
    I3 -->|No| I5[Vision Caption GPT-4V]
    I5 --> I6[Text Embedding from Caption]
    I6 --> I7[Hybrid Embedding]
    I7 --> I8[Re-search Vector Store]
    I8 --> I4
    I4 --> End
    
    ChatSearch --> C1[Text Embedding]
    C1 --> C2[SQL Keyword Search]
    C2 --> C3[Vector Search]
    C3 --> C4[Lexical Filter]
    C4 --> C5{Results Found?}
    C5 -->|Yes| C6[Fetch Product Details]
    C5 -->|No| C7[Fallback: Popular Products]
    C6 --> C8[Generate LLM Response]
    C7 --> C8
    C8 --> End
    
    style Start fill:#4CAF50,stroke:#2E7D32,color:#fff
    style End fill:#2196F3,stroke:#1565C0,color:#fff
    style TextSearch fill:#FF9800,stroke:#E65100,color:#fff
    style ImageSearch fill:#9C27B0,stroke:#6A1B9A,color:#fff
    style ChatSearch fill:#00BCD4,stroke:#00838F,color:#fff
```

---

## 9. 💳 Payment Flow

```mermaid
sequenceDiagram
    participant U as User
    participant F as Flutter App
    participant B as Backend API
    participant S as Stripe API
    participant DB as Database
    
    U->>F: 1. Place Order
    F->>B: 2. POST /api/Orders
    B->>DB: 3. Create Order (Pending)
    DB-->>B: Order Created
    B->>S: 4. Create Payment Intent
    S-->>B: Payment Intent ID
    B->>DB: 5. Update Order with Intent ID
    B-->>F: 6. Return Payment Details
    
    F->>S: 7. Process Payment (Card/QR)
    S->>S: 8. Validate Payment
    S-->>F: 9. Payment Result
    
    alt Payment Success
        S->>B: 10. Webhook: payment_intent.succeeded
        B->>DB: 11. Update Order Status (Confirmed)
        B->>DB: 12. Update Product Stock
        B->>F: 13. Send Push Notification
        F-->>U: 14. Order Confirmed
    else Payment Failed
        S->>B: 10. Webhook: payment_intent.failed
        B->>DB: 11. Update Order Status (Failed)
        B-->>F: 12. Payment Failed Notification
        F-->>U: 13. Payment Error
    end
```

---

## 10. 📊 State Management Flow (Flutter)

```mermaid
graph LR
    A[User Action] --> B[Widget]
    B --> C{State Type?}
    
    C -->|Local| D[setState]
    C -->|Global| E[Provider]
    C -->|Reactive| F[ValueNotifier]
    
    D --> G[Rebuild Widget]
    E --> H[Notify Listeners]
    F --> I[ValueListenableBuilder]
    
    H --> G
    I --> G
    
    G --> J[UI Update]
    
    K[API Call] --> L[Service Layer]
    L --> M[Update State]
    M --> E
    M --> F
    
    style A fill:#4CAF50,stroke:#2E7D32,color:#fff
    style B fill:#2196F3,stroke:#1565C0,color:#fff
    style E fill:#FF9800,stroke:#E65100,color:#fff
    style F fill:#9C27B0,stroke:#6A1B9A,color:#fff
    style J fill:#00BCD4,stroke:#00838F,color:#fff
```

---

## 11. 🔐 Authentication & Authorization Flow

```mermaid
sequenceDiagram
    participant U as User
    participant F as Flutter App
    participant FB as Firebase Auth
    participant B as Backend API
    participant DB as Database
    
    U->>F: 1. Login Request
    F->>FB: 2. Authenticate
    FB-->>F: 3. Firebase Token
    
    F->>B: 4. POST /api/User/login<br/>(Firebase Token)
    B->>FB: 5. Verify Token
    FB-->>B: 6. User Info
    
    B->>DB: 7. Get/Create User
    DB-->>B: 8. User Data + Role
    
    B->>B: 9. Generate JWT Token
    B-->>F: 10. JWT Token + User Info
    
    F->>F: 11. Store Token (SharedPreferences)
    
    Note over F,B: Subsequent Requests
    F->>B: 12. API Request + JWT Token
    B->>B: 13. Validate JWT
    B->>DB: 14. Check User Role
    DB-->>B: 15. Role Info
    
    alt Authorized
        B->>B: 16. Process Request
        B-->>F: 17. Response
    else Unauthorized
        B-->>F: 18. 401 Unauthorized
    end
```

---

## 12. 📦 Deployment Architecture

```mermaid
graph TB
    subgraph "Production Environment"
        subgraph "Load Balancer"
            LB[Nginx/Cloud Load Balancer]
        end
        
        subgraph "Application Servers"
            B1[Backend API Server 1]
            B2[Backend API Server 2]
            R1[RAG Service Server 1]
            R2[RAG Service Server 2]
        end
        
        subgraph "Database Cluster"
            DB1[(SQL Server Primary)]
            DB2[(SQL Server Replica)]
            VDB[(ChromaDB Cluster)]
        end
        
        subgraph "External Services"
            OAI[OpenAI API]
            STR[Stripe API]
            FB[Firebase]
        end
        
        subgraph "Storage"
            S3[Image Storage<br/>Firebase Storage]
            CDN[CDN for Static Assets]
        end
    end
    
    LB --> B1
    LB --> B2
    B1 --> DB1
    B2 --> DB2
    B1 --> R1
    B2 --> R2
    R1 --> VDB
    R2 --> VDB
    R1 --> OAI
    R2 --> OAI
    B1 --> STR
    B2 --> STR
    B1 --> FB
    B2 --> FB
    B1 --> S3
    B2 --> S3
    S3 --> CDN
    
    style LB fill:#2196F3,stroke:#1565C0,color:#fff
    style B1 fill:#4CAF50,stroke:#2E7D32,color:#fff
    style B2 fill:#4CAF50,stroke:#2E7D32,color:#fff
    style R1 fill:#FF9800,stroke:#E65100,color:#fff
    style R2 fill:#FF9800,stroke:#E65100,color:#fff
    style DB1 fill:#9C27B0,stroke:#6A1B9A,color:#fff
    style VDB fill:#00BCD4,stroke:#00838F,color:#fff
```

---

## 📝 Notes

- **Ports:**
  - Flutter App: Mobile (no fixed port)
  - Backend API: 5000 (HTTP), 5001 (HTTPS)
  - RAG Service: 8000 (HTTP)
  - SQL Server: 1433 (default)
  - ChromaDB: Embedded (no external port)

- **Technologies:**
  - Frontend: Flutter 3.0+, Dart 3.0+
  - Backend: ASP.NET Core 8.0, C#
  - RAG Service: Python 3.8+, FastAPI
  - Database: SQL Server
  - Vector Store: ChromaDB
  - AI: OpenAI GPT-4, Embeddings, CLIP

- **Key Features:**
  - Real-time chat with RAG
  - Image-to-image product search
  - Function calling for database queries
  - Payment processing with Stripe
  - Push notifications with Firebase
  - Multi-language support (Vi/En)
  - Dark/Light theme

---

**Generated:** 2026-02-02  
**Version:** 1.0.0

