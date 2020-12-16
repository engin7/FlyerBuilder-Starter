 

import UIKit
import PDFKit

class PDFCreator: NSObject {

  func createFlyer() -> Data {
    // 1- create metadata and set the document info
    let pdfMetaData = [
      kCGPDFContextCreator: "Flyer Builder",
      kCGPDFContextAuthor: "raywenderlich.com"
    ]
    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = pdfMetaData as [String: Any]

    // 2- pdf files use coordinate system 72 px per inch. You create U.S. letter size
    let pageWidth = 8.5 * 72.0
    let pageHeight = 11 * 72.0
    let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

    // 3- create a PDFRenderer object with settings you made above
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
    // 4- includes a block where you create the PDF. The renderer creates a Core Graphics context that becomes the current context within the block. Drawing done on this context will appear on the PDF.
    let data = renderer.pdfData { (context) in
      // 5- starts new pdf page (call it more to create multiple pages)
      context.beginPage()
      // 6- Using draw(at:withAttributes:) on a String draws the string to the current context.
      let attributes = [
        NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 72)
      ]
      let text = "I'm a PDF!"
      text.draw(at: CGPoint(x: 0, y: 0), withAttributes: attributes)
    }

    return data
  }

  
  
  
}
