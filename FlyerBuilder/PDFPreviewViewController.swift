 

import UIKit
import PDFKit

class PDFPreviewViewController: UIViewController {
  @IBOutlet weak var pdfView: PDFView!
 
  public var documentData: Data?
 
  override func viewDidLoad() {
    super.viewDidLoad()
    // PDFDocument is a PDFKit object that represents PDF data. Assign the document to the PDFView view and set the document to scale to fit the view.
    if let data = documentData {
      pdfView.document = PDFDocument(data: data)
      pdfView.autoScales = true
    }

  }
}
