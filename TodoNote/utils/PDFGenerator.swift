//
//  PDFGenerator.swift
//  TodoNote
//
//  Created by xrt on 2026/1/29.
//

import UIKit
import PDFKit

class PDFGenerator {
    
    static func createPDF(from note: Note) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "TodoNote App",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: note.title
        ]
        
        // A4 size: 595.2 x 841.8
        let pageWidth: CGFloat = 595.2
        let pageHeight: CGFloat = 841.8
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            // Draw Title
            let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont
            ]
            let titleString = note.title
            
            // Calculate multi-line height
            let maxTitleWidth = pageWidth - 80
            let titleSize = titleString.boundingRect(
                with: CGSize(width: maxTitleWidth, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: titleAttributes,
                context: nil
            ).size
            
            let titleRect = CGRect(x: 40, y: 40, width: maxTitleWidth, height: titleSize.height)
            titleString.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Draw Content
            
            let contentFont = UIFont.systemFont(ofSize: 14, weight: .regular)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6
            
            let contentAttributes: [NSAttributedString.Key: Any] = [
                .font: contentFont,
                .paragraphStyle: paragraphStyle
            ]
            
            let contentString = note.content
            let contentY = titleRect.maxY + 20
            let contentRect = CGRect(x: 40, y: contentY, width: pageWidth - 80, height: pageHeight - contentY - 40)
            
            contentString.draw(in: contentRect, withAttributes: contentAttributes)
        }
        
        return savePDFData(data, filename: "Note_\(note.id).pdf")
    }
    
    private static func savePDFData(_ data: Data, filename: String) -> URL? {
        // Save to temporary directory or Documents directory
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
             return nil
        }
        let fileURL = documentsDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("PDF saved to: \(fileURL.path)")
            return fileURL
        } catch {
            print("Could not save PDF: \(error)")
            return nil
        }
    }
}
