-- Script tạo các bảng cho RAG (Retrieval Augmented Generation) system
-- Chạy script này để tạo các bảng Document và DocumentChunk

USE FressFood;
GO

-- Tạo bảng Document để lưu metadata của các file đã upload
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Document')
BEGIN
    CREATE TABLE Document (
        FileId NVARCHAR(50) PRIMARY KEY,
        FileName NVARCHAR(500) NOT NULL,
        UploadDate DATETIME NOT NULL DEFAULT GETDATE(),
        FileType NVARCHAR(10),
        TotalChunks INT DEFAULT 0
    );
    
    PRINT 'Table Document created successfully';
END
ELSE
BEGIN
    PRINT 'Table Document already exists';
END
GO

-- Tạo bảng DocumentChunk để lưu các chunks và embeddings
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DocumentChunk')
BEGIN
    CREATE TABLE DocumentChunk (
        ChunkId NVARCHAR(100) PRIMARY KEY,
        FileId NVARCHAR(50) NOT NULL,
        FileName NVARCHAR(500) NOT NULL,
        ChunkIndex INT NOT NULL,
        Text NVARCHAR(MAX) NOT NULL,
        StartIndex INT,
        EndIndex INT,
        Embedding NVARCHAR(MAX), -- JSON array of floats
        CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
        FOREIGN KEY (FileId) REFERENCES Document(FileId) ON DELETE CASCADE
    );
    
    PRINT 'Table DocumentChunk created successfully';
END
ELSE
BEGIN
    PRINT 'Table DocumentChunk already exists';
END
GO

-- Tạo indexes để tìm kiếm nhanh
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DocumentChunk_FileId')
BEGIN
    CREATE INDEX IX_DocumentChunk_FileId ON DocumentChunk(FileId);
    PRINT 'Index IX_DocumentChunk_FileId created successfully';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DocumentChunk_FileName')
BEGIN
    CREATE INDEX IX_DocumentChunk_FileName ON DocumentChunk(FileName);
    PRINT 'Index IX_DocumentChunk_FileName created successfully';
END
GO

PRINT 'RAG tables initialization completed!';
GO

