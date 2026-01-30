# RAG Service Architecture

## Cấu trúc thư mục

```
rag_service/
├── app/
│   ├── main.py                    # FastAPI application entry point
│   │
│   ├── api/                       # API Layer - HTTP handlers
│   │   ├── routes/
│   │   │   ├── product_route.py  # Product management endpoints
│   │   │   ├── search_route.py   # Search endpoints (image, text, chat)
│   │   │   └── chat_route.py     # Chat-specific endpoints
│   │   ├── schemas/               # Request/Response models
│   │   │   ├── search_request.py
│   │   │   └── search_response.py
│   │   └── deps.py                # Dependency injection
│   │
│   ├── core/                      # Core Business Logic
│   │   ├── pipelines/             # Data processing pipelines
│   │   │   ├── product_ingest_pipeline.py
│   │   │   ├── search_pipeline.py
│   │   │   └── chat_pipeline.py
│   │   ├── ranking/               # Ranking algorithms
│   │   │   └── hybrid_ranker.py
│   │   ├── cache/                 # Caching layer
│   │   │   └── embedding_cache.py
│   │   └── settings.py            # Application settings
│   │
│   ├── domain/                    # Domain Layer - Business entities
│   │   ├── models/                # Domain models
│   │   │   ├── product.py
│   │   │   ├── embedding.py
│   │   │   └── search.py
│   │   ├── services/              # Domain services
│   │   │   ├── semantic_service.py
│   │   │   └── ranking_service.py
│   │   └── interfaces/            # Abstract interfaces
│   │       ├── llm_interface.py
│   │       ├── vector_store_interface.py
│   │       └── repository_interface.py
│   │
│   ├── infrastructure/            # Infrastructure Layer - External dependencies
│   │   ├── database/              # Database access
│   │   │   ├── sql_repository.py
│   │   │   └── models.py
│   │   ├── vector_store/          # Vector database
│   │   │   ├── image_vector_store.py
│   │   │   └── chroma.py
│   │   └── llm/                   # LLM providers
│   │       ├── openai.py
│   │       └── embedding_service.py
│   │
│   ├── services/                  # Application Services - Business logic
│   │   ├── product_service.py     # Product operations
│   │   ├── search_service.py      # Search operations
│   │   └── chat_service.py        # Chat operations
│   │
│   └── utils/                     # Utilities
│       ├── image_utils.py
│       └── text_utils.py
│
├── requirements.txt
└── README.md
```

## Layer Responsibilities

### API Layer (`app/api/`)
- **Routes**: Handle HTTP requests/responses, validation
- **Schemas**: Request/Response models (Pydantic)
- **Deps**: Dependency injection for FastAPI

### Core Layer (`app/core/`)
- **Pipelines**: Business logic workflows
- **Ranking**: Search result ranking algorithms
- **Cache**: Caching strategies

### Domain Layer (`app/domain/`)
- **Models**: Business entities (pure Python classes)
- **Services**: Domain-specific business logic
- **Interfaces**: Abstract contracts for infrastructure

### Infrastructure Layer (`app/infrastructure/`)
- **Database**: SQL Server access
- **Vector Store**: ChromaDB/FAISS access
- **LLM**: OpenAI/other LLM providers

### Services Layer (`app/services/`)
- **Application Services**: Orchestrate domain logic and infrastructure
- Coordinate between domain, infrastructure, and core layers

## Refactoring Progress

- [x] Create directory structure
- [x] Create API schemas
- [ ] Split routes (product_route, search_route)
- [ ] Move pipelines to core/pipelines
- [ ] Create domain models
- [ ] Create application services
- [ ] Update imports
