using System.Text;
using System.Text.RegularExpressions;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using PdfSharpCore.Pdf;
using PdfSharpCore.Pdf.IO;
using OfficeOpenXml;

namespace FressFood.Services
{
    /// <summary>
    /// Service xử lý các loại file document (docx, txt, pdf, xlsx)
    /// Extract text và chunk thành các đoạn nhỏ
    /// </summary>
    public class DocumentProcessor
    {
        private readonly ILogger<DocumentProcessor> _logger;
        private const int ChunkSize = 500; // Kích thước mỗi chunk (số ký tự)
        private const int ChunkOverlap = 50; // Số ký tự overlap giữa các chunk

        public DocumentProcessor(ILogger<DocumentProcessor> logger)
        {
            _logger = logger;
            // Set license context cho EPPlus (free cho non-commercial use)
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
        }

        /// <summary>
        /// Xử lý file và trả về danh sách các chunks
        /// </summary>
        public async Task<List<DocumentChunk>> ProcessDocumentAsync(Stream fileStream, string fileName, string? fileId = null)
        {
            var extension = Path.GetExtension(fileName).ToLower();
            string text;

            try
            {
                switch (extension)
                {
                    case ".txt":
                        text = await ExtractTextFromTxtAsync(fileStream);
                        break;
                    case ".docx":
                        text = await ExtractTextFromDocxAsync(fileStream);
                        break;
                    case ".pdf":
                        text = await ExtractTextFromPdfAsync(fileStream);
                        break;
                    case ".xlsx":
                        text = await ExtractTextFromXlsxAsync(fileStream);
                        break;
                    default:
                        throw new NotSupportedException($"File type {extension} is not supported");
                }

                if (string.IsNullOrWhiteSpace(text))
                {
                    _logger.LogWarning($"No text extracted from file {fileName}");
                    return new List<DocumentChunk>();
                }

                // Chunk text thành các đoạn nhỏ
                var chunks = ChunkText(text, fileName, fileId);
                
                _logger.LogInformation($"Processed {fileName}: {chunks.Count} chunks created from {text.Length} characters");
                return chunks;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error processing document {fileName}");
                throw;
            }
        }

        /// <summary>
        /// Extract text từ file TXT
        /// </summary>
        private async Task<string> ExtractTextFromTxtAsync(Stream stream)
        {
            stream.Position = 0;
            using var reader = new StreamReader(stream, Encoding.UTF8);
            return await reader.ReadToEndAsync();
        }

        /// <summary>
        /// Extract text từ file DOCX
        /// </summary>
        private async Task<string> ExtractTextFromDocxAsync(Stream stream)
        {
            return await Task.Run(() =>
            {
                stream.Position = 0;
                var text = new StringBuilder();
                
                using (var wordDoc = WordprocessingDocument.Open(stream, false))
                {
                    var body = wordDoc.MainDocumentPart?.Document?.Body;
                    if (body != null)
                    {
                        foreach (var paragraph in body.Elements<Paragraph>())
                        {
                            var paraText = paragraph.InnerText;
                            if (!string.IsNullOrWhiteSpace(paraText))
                            {
                                text.AppendLine(paraText);
                            }
                        }
                    }
                }
                
                return text.ToString();
            });
        }

        /// <summary>
        /// Extract text từ file PDF
        /// </summary>
        private async Task<string> ExtractTextFromPdfAsync(Stream stream)
        {
            return await Task.Run(() =>
            {
                stream.Position = 0;
                var text = new StringBuilder();
                
                try
                {
                    using var document = PdfReader.Open(stream, PdfDocumentOpenMode.ReadOnly);
                    int pageIndex = 1;
                    foreach (var page in document.Pages)
                    {
                        // PdfSharpCore không có built-in text extraction
                        // Cần dùng thư viện khác như iText7 hoặc chỉ extract metadata
                        // Tạm thời chỉ đánh dấu page number, không extract text
                        // PDF sẽ được xử lý bởi Python RAG service
                        text.AppendLine($"[Page {pageIndex}]");
                        text.AppendLine("(PDF text extraction not supported with PdfSharpCore. Please use Python RAG service for PDF processing.)");
                        pageIndex++;
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PDF text extraction may not be fully supported. Consider using iText7 or Python RAG service.");
                }
                
                return text.ToString();
            });
        }

        /// <summary>
        /// Extract text từ file XLSX
        /// </summary>
        private async Task<string> ExtractTextFromXlsxAsync(Stream stream)
        {
            return await Task.Run(() =>
            {
                stream.Position = 0;
                var text = new StringBuilder();
                
                using var package = new ExcelPackage(stream);
                var workbook = package.Workbook;
                
                foreach (var worksheet in workbook.Worksheets)
                {
                    text.AppendLine($"Sheet: {worksheet.Name}");
                    
                    var startRow = worksheet.Dimension?.Start.Row ?? 1;
                    var endRow = worksheet.Dimension?.End.Row ?? 1;
                    var startCol = worksheet.Dimension?.Start.Column ?? 1;
                    var endCol = worksheet.Dimension?.End.Column ?? 1;
                    
                    for (int row = startRow; row <= endRow; row++)
                    {
                        var rowText = new List<string>();
                        for (int col = startCol; col <= endCol; col++)
                        {
                            var cellValue = worksheet.Cells[row, col].Value?.ToString();
                            if (!string.IsNullOrWhiteSpace(cellValue))
                            {
                                rowText.Add(cellValue);
                            }
                        }
                        if (rowText.Any())
                        {
                            text.AppendLine(string.Join(" | ", rowText));
                        }
                    }
                }
                
                return text.ToString();
            });
        }

        /// <summary>
        /// Chunk text thành các đoạn nhỏ với overlap
        /// </summary>
        private List<DocumentChunk> ChunkText(string text, string fileName, string? fileId)
        {
            var chunks = new List<DocumentChunk>();
            var cleanedText = CleanText(text);
            
            if (string.IsNullOrWhiteSpace(cleanedText))
                return chunks;

            int startIndex = 0;
            int chunkIndex = 0;

            while (startIndex < cleanedText.Length)
            {
                int endIndex = Math.Min(startIndex + ChunkSize, cleanedText.Length);
                
                // Tìm điểm cắt tốt (kết thúc câu hoặc đoạn)
                if (endIndex < cleanedText.Length)
                {
                    // Tìm dấu chấm câu gần nhất
                    int lastPeriod = cleanedText.LastIndexOf('.', endIndex - 1, Math.Min(100, endIndex - startIndex));
                    int lastNewline = cleanedText.LastIndexOf('\n', endIndex - 1, Math.Min(100, endIndex - startIndex));
                    
                    int bestBreak = Math.Max(lastPeriod, lastNewline);
                    if (bestBreak > startIndex + ChunkSize / 2) // Chỉ dùng nếu không quá xa
                    {
                        endIndex = bestBreak + 1;
                    }
                }

                var chunkText = cleanedText.Substring(startIndex, endIndex - startIndex).Trim();
                
                if (!string.IsNullOrWhiteSpace(chunkText))
                {
                    chunks.Add(new DocumentChunk
                    {
                        Id = $"{fileId ?? Guid.NewGuid().ToString()}_chunk_{chunkIndex}",
                        FileId = fileId,
                        FileName = fileName,
                        Text = chunkText,
                        ChunkIndex = chunkIndex,
                        StartIndex = startIndex,
                        EndIndex = endIndex
                    });
                    chunkIndex++;
                }

                // Di chuyển startIndex với overlap
                startIndex = Math.Max(startIndex + 1, endIndex - ChunkOverlap);
            }

            return chunks;
        }

        /// <summary>
        /// Làm sạch text: loại bỏ khoảng trắng thừa, normalize
        /// </summary>
        private string CleanText(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return string.Empty;

            // Loại bỏ khoảng trắng thừa
            var cleaned = Regex.Replace(text, @"\s+", " ", RegexOptions.Multiline);
            // Loại bỏ các ký tự đặc biệt không cần thiết
            cleaned = Regex.Replace(cleaned, @"[\x00-\x08\x0B-\x0C\x0E-\x1F]", "");
            
            return cleaned.Trim();
        }
    }

    /// <summary>
    /// Model đại diện cho một chunk của document
    /// </summary>
    public class DocumentChunk
    {
        public string Id { get; set; } = string.Empty;
        public string? FileId { get; set; }
        public string FileName { get; set; } = string.Empty;
        public string Text { get; set; } = string.Empty;
        public int ChunkIndex { get; set; }
        public int StartIndex { get; set; }
        public int EndIndex { get; set; }
    }
}

