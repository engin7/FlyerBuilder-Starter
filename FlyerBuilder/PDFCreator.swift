 

import UIKit
import PDFKit

class PDFCreator: NSObject {
  
  let title: String
  let body: String
  let image: UIImage
  let contactInfo: String

  init(title: String, body: String, image: UIImage, contact: String) {
    self.title = title
    self.body = body
    self.image = image
    self.contactInfo = contact
  }

  
  func createFlyer() -> Data {
    // 1- create metadata and set the document info
    let pdfMetaData = [
      kCGPDFContextCreator: "Flyer Builder",
      kCGPDFContextAuthor: "raywenderlich.com",
      kCGPDFContextTitle: title
    ]
    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = pdfMetaData as [String: Any]

    // 2- pdf files use coordinate system 72 px per inch. You create U.S. letter size
    let pageWidth = 8.5 * 72.0
    let pageHeight = 11 * 72.0
    let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

    // 3- create a PDFRenderer object with settings you made above
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
    // 4- includes a block where you create the PDF. The renderer creates a Core Graphics context that becomes the current context within the block. Drawing done on this context will appear on the PDF. Core Graphics context begin at the top left corner and increase down and to the right. So you don't need to convert to PDF coordinate systme.
    let data = renderer.pdfData { (context) in
      // 5- starts new pdf page (call it more to create multiple pages)
      context.beginPage()
      let titleBottom = addTitle(pageRect: pageRect)
      // add a half-inch of space between the title and body text. 
      let imageBottom = addImage(pageRect: pageRect, imageTop: titleBottom + 18.0)
      addBodyText(pageRect: pageRect, textTop: imageBottom + 18.0)
      // adding dashed lines. You need a Core Graphics context to pass to this method. Use cgContext on the UIGraphicsPDFRendererContext to get one:
      let context = context.cgContext
      drawTearOffs(context, pageRect: pageRect, tearOffY: pageRect.height * 4.0 / 5.0,
                   numberTabs: 8)
      drawContactLabels(context, pageRect: pageRect, numberTabs: 8)

    }

    return data
  }

  //MARK: - CoreText
  
  func addTitle(pageRect: CGRect) -> CGFloat {
    // 1- create instance of System font
    let titleFont = UIFont.systemFont(ofSize: 18.0, weight: .bold)
    // 2-
    let titleAttributes: [NSAttributedString.Key: Any] =
      [NSAttributedString.Key.font: titleFont]
    // 3- you create NSAttributedString containing the text of the title in the chosen font.
    let attributedTitle = NSAttributedString(
      string: title,
      attributes: titleAttributes
    )
    // 4- Using size() on the attributed string returns a rectangle with the size the text will occupy in the current context.
    let titleStringSize = attributedTitle.size()
    // 5- using additional layout functionality provided by Core Text.
    let titleStringRect = CGRect(
      x: (pageRect.width - titleStringSize.width) / 2.0, // centering
      y: 36,
      width: titleStringSize.width,
      height: titleStringSize.height
    )
    // 6- draw inside the rectangle
    attributedTitle.draw(in: titleStringRect)
    // 7- find the coordinate of the bottom of the rectangle and return
    return titleStringRect.origin.y + titleStringRect.size.height
  }

  //MARK: - NSParagraphStyle
  
  func addBodyText(pageRect: CGRect, textTop: CGFloat) {
    let textFont = UIFont.systemFont(ofSize: 12.0, weight: .regular)
    // 1- Natural alignment sets the alignment based on the localization of the app. Lines are set to wrap at word breaks.
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .natural
    paragraphStyle.lineBreakMode = .byWordWrapping
    // 2
    let textAttributes = [
      NSAttributedString.Key.paragraphStyle: paragraphStyle,
      NSAttributedString.Key.font: textFont
    ]
    let attributedText = NSAttributedString(
      string: body,
      attributes: textAttributes
    )
    // 3- offsets 10 points from the left and sets the top at the passed value. The width is set to the width of the page minus a margin of 10 points on each side. The height is the distance from the top to 1/5 of the page height from the bottom.
    let textRect = CGRect(
      x: 10,
      y: textTop,
      width: pageRect.width - 20,
      height: pageRect.height - textTop - pageRect.height / 5.0
    )
    attributedText.draw(in: textRect)
  }

  //MARK: - Adding Images to PDF
  
  func addImage(pageRect: CGRect, imageTop: CGFloat) -> CGFloat {
    // 1
    let maxHeight = pageRect.height * 0.4
    let maxWidth = pageRect.width * 0.8
    // 2- This ratio maximizes the size of the image while ensuring that it fits within the constraints.
    let aspectWidth = maxWidth / image.size.width
    let aspectHeight = maxHeight / image.size.height
    let aspectRatio = min(aspectWidth, aspectHeight)
    // 3- Calculate the scaled height and width for the image using the ratio.
    let scaledWidth = image.size.width * aspectRatio
    let scaledHeight = image.size.height * aspectRatio
    // 4- Calculate the horizontal offset to center the image, just as you did earlier with the title text. Create a rectangle at this coordinate with the size you’ve calculated.
    let imageX = (pageRect.width - scaledWidth) / 2.0
    let imageRect = CGRect(x: imageX, y: imageTop,
                           width: scaledWidth, height: scaledHeight)
    // 5- This method scales the image to fit within the rectangle. Finally, return the coordinate of the bottom of the image to the caller, just as you did with the title text.
    image.draw(in: imageRect)
    return imageRect.origin.y + imageRect.size.height
  }
  
  //MARK: - Drawing Graphics

  // First, you’ll add lines on the page to separate the tear-off tabs. Then you’ll add the contact information to each tab.
  // 1- parameters: Graphics Context to draw on, rectangle of page, location, # of tabs
  func drawTearOffs(_ drawContext: CGContext, pageRect: CGRect,
                    tearOffY: CGFloat, numberTabs: Int) {
    // 2- save the current state of the graphics context. Later, you'll restore the context, undoing all changes made between the two calls. This pairing keeps the environment consistent at the start of each step.
    drawContext.saveGState()
    // 3- stroke line width
    drawContext.setLineWidth(2.0)
    // 4- draw a horizontal line from the left to right side of the page at the passed height and then restore the state saved earlier.
    drawContext.move(to: CGPoint(x: 0, y: tearOffY))
    drawContext.addLine(to: CGPoint(x: pageRect.width, y: tearOffY))
    drawContext.strokePath()
    drawContext.restoreGState()

    // 5-  you define an array with the length of the alternating solid and empty segments. Here, the array defines both the dashes and the spaces as 0.2 inches long.
    drawContext.saveGState()
    let dashLength = CGFloat(72.0 * 0.2)
    drawContext.setLineDash(phase: 0, lengths: [dashLength, dashLength])
    // 6- calculate tabWidth
    let tabWidth = pageRect.width / CGFloat(numberTabs)
    for tearOffIndex in 1..<numberTabs {
      // 7- draw in loop
      let tabX = CGFloat(tearOffIndex) * tabWidth
      drawContext.move(to: CGPoint(x: tabX, y: tearOffY))
      drawContext.addLine(to: CGPoint(x: tabX, y: pageRect.height))
      drawContext.strokePath()
    }
    // 7- After you've drawn all the lines, you restore the graphics state.
    drawContext.restoreGState()
  }

  //MARK: - Adding Rotated Text

  func drawContactLabels(
      _ drawContext: CGContext,
      pageRect: CGRect, numberTabs: Int) {
    let contactTextFont = UIFont.systemFont(ofSize: 10.0, weight: .regular)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .natural
    paragraphStyle.lineBreakMode = .byWordWrapping
    let contactBlurbAttributes = [
      NSAttributedString.Key.paragraphStyle: paragraphStyle,
      NSAttributedString.Key.font: contactTextFont
    ]
    let attributedContactText = NSMutableAttributedString(
                                  string: contactInfo,
                                  attributes: contactBlurbAttributes
                                )
    // 1- You use size() to find the smallest size required to draw the string in the current context. You use height of the text to center it in the tabs. (because its rotated)
    let textHeight = attributedContactText.size().height
    let tabWidth = pageRect.width / CGFloat(numberTabs)
    let horizontalOffset = (tabWidth - textHeight) / 2.0
    drawContext.saveGState()
    // 2- You want to rotate the text 90 degrees counterclockwise. You indicate counterclockwise with a negative angle transform. Core Graphics expects angles specified in radians.
    drawContext.rotate(by: -90.0 * CGFloat.pi / 180.0)
    for tearOffIndex in 0...numberTabs {
      let tabX = CGFloat(tearOffIndex) * tabWidth + horizontalOffset
      // 3- rotation changes coordinate system.
      attributedContactText.draw(at: CGPoint(x: -pageRect.height + 5.0, y: tabX))
    }
    drawContext.restoreGState()
  }
 
}
