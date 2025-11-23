import Foundation
import PDFKit
import SwiftUI

struct PDFGenerator {
    /// Generates a PDF document from expenses
    static func generatePDF(from expenses: [Expense]) -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "TapBudget",
            kCGPDFContextAuthor: "TapBudget App",
            kCGPDFContextTitle: "Expense Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0 // US Letter width in points
        let pageHeight = 11 * 72.0 // US Letter height in points
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 72 // Start 1 inch from top
            let margin: CGFloat = 72
            let contentWidth = pageWidth - (margin * 2)
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.label
            ]
            let title = "Expense Report"
            let titleSize = title.size(withAttributes: titleAttributes)
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += titleSize.height + 20
            
            // Date range
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateRangeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            if let firstDate = expenses.first?.date, let lastDate = expenses.last?.date {
                let dateRange = "\(dateFormatter.string(from: firstDate)) - \(dateFormatter.string(from: lastDate))"
                dateRange.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateRangeAttributes)
                yPosition += 20
            }
            
            // Summary
            let totalAmount = expenses.reduce(0) { $0 + $1.amount }
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
            let summary = "Total Expenses: \(totalAmount.formattedAsCurrency())"
            summary.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: summaryAttributes)
            yPosition += 30
            
            // Table headers
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ]
            
            let columnWidths: [CGFloat] = [contentWidth * 0.25, contentWidth * 0.25, contentWidth * 0.25, contentWidth * 0.25]
            let headers = ["Date", "Category", "Amount", "Notes"]
            var xPosition = margin
            
            for (index, header) in headers.enumerated() {
                header.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: headerAttributes)
                xPosition += columnWidths[index]
            }
            
            yPosition += 20
            
            // Draw line under headers
            context.cgContext.setStrokeColor(UIColor.separator.cgColor)
            context.cgContext.setLineWidth(1.0)
            context.cgContext.move(to: CGPoint(x: margin, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
            context.cgContext.strokePath()
            yPosition += 10
            
            // Table rows
            let rowAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.label
            ]
            
            let lineHeight: CGFloat = 15
            let maxRowsPerPage = Int((pageHeight - yPosition - margin) / lineHeight)
            var currentRow = 0
            
            for expense in expenses {
                // Check if we need a new page
                if currentRow >= maxRowsPerPage {
                    context.beginPage()
                    yPosition = margin
                    currentRow = 0
                    
                    // Redraw headers on new page
                    xPosition = margin
                    for (index, header) in headers.enumerated() {
                        header.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: headerAttributes)
                        xPosition += columnWidths[index]
                    }
                    yPosition += 20
                    
                    context.cgContext.move(to: CGPoint(x: margin, y: yPosition))
                    context.cgContext.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
                    context.cgContext.strokePath()
                    yPosition += 10
                }
                
                xPosition = margin
                
                // Date
                let dateString = dateFormatter.string(from: expense.date)
                dateString.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: rowAttributes)
                xPosition += columnWidths[0]
                
                // Category
                let categoryName = expense.category?.name ?? "Uncategorized"
                categoryName.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: rowAttributes)
                xPosition += columnWidths[1]
                
                // Amount
                let amountString = expense.amount.formattedAsCurrency()
                amountString.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: rowAttributes)
                xPosition += columnWidths[2]
                
                // Notes (truncate if too long)
                let notes = expense.notes ?? ""
                let truncatedNotes = notes.count > 30 ? String(notes.prefix(27)) + "..." : notes
                truncatedNotes.draw(at: CGPoint(x: xPosition, y: yPosition), withAttributes: rowAttributes)
                
                yPosition += lineHeight
                currentRow += 1
            }
        }
        
        return data
    }
}

