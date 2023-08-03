import TensorFlowLite
import Vision

public struct DAOFaceCompare {
    // Constants
    private let modelFileName = "FaceNet"
    private let modelFileType = "tflite"
    private let imageWidth = 112
    private let imageHeight = 112
    private let embeddingsSize = 192
    private let domain = "org.cocoapods.daofacecompare"
    
    private let interpreter: Interpreter
    private let utility = Utility()
    
    public init() throws {
        let modelPath = utility.filePath(forResourceName: modelFileName, extension: modelFileType)!
        var options = Interpreter.Options()
        options.threadCount = 4
        try interpreter = Interpreter.init(modelPath: modelPath, options: options, delegates: nil)
    }
    
    public func compare(_ image1: UIImage, with image2: UIImage, completion: @escaping (Result<Float, Error>)->()) {
        var faceImage1: UIImage?
        var faceImage2: UIImage?
        let group = DispatchGroup()
        group.enter()
        getFace(in: image1) { result in
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let image):
                faceImage1 = image
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        group.enter()
        getFace(in: image2) { result in
            defer {
                group.leave()
            }
            
            switch result {
            case .success(let image):
                faceImage2 = image
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        group.notify(queue: .main) {
            let size = CGSize(width: imageWidth, height: imageHeight)
            guard let faceImage1 = faceImage1,
                  let faceImage2 = faceImage2,
                  let imageScale1 = faceImage1.resize(to: size),
                  let imageScale2 = faceImage2.resize(to: size),
                  let data = data(withProcess: imageScale1, image2: imageScale2) else {
                
                let error = NSError(domain: domain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to preprocess images."])
                
                completion(.failure(error))
                return
            }
            
            do {
                // Perform forward propagation
                try interpreter.allocateTensors()
                try interpreter.copy(data, toInputAt: 0)
                try interpreter.invoke()
                let outputTensor = try interpreter.output(at: 0)
                let outputData = outputTensor.data
                
                // Get the forward propagation result
                var output = [Float](repeating: 0, count: 2 * embeddingsSize)
                outputData.withUnsafeBytes { rawPointer in
                    let floatPointer = rawPointer.bindMemory(to: Float.self)
                    for i in 0..<2 * embeddingsSize {
                        output[i] = floatPointer[i]
                    }
                }
                
                l2Normalize(&output, epsilon: 1e-10)
                let score = evaluate(&output)
                completion(.success(score))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func data(withProcess image1: UIImage, image2: UIImage) -> Data? {
        guard let imageData1 = utility.convertUIImageToBitmapRGBA8(image1),
              let imageData2 = utility.convertUIImageToBitmapRGBA8(image2) else {
            return nil
        }
        let image_datas = [imageData1, imageData2]
        var floats = [Float](repeating: 0, count: 2 * imageWidth * imageHeight * 3)

        // Normalize the images and put them into tensors. Since iOS images have 4 channels (RGBA), the alpha channel needs to be filtered out
        let input_mean: Float = 127.5
        let input_std: Float = 128.0
        var k = 0
        for i in 0..<2 {
            let image_data = image_datas[i]
            let size = imageWidth * imageHeight * 4
            for j in 0..<size {
                if j % 4 == 3 {
                    continue
                }
                floats[k] = (Float(image_data[j]) - input_mean) / input_std
                k += 1
            }
        }
        free(imageData1)
        free(imageData2)

        return Data(bytes: &floats, count: MemoryLayout<Float>.size * 2 * imageWidth * imageHeight * 3)
    }
    
    private func l2Normalize(_ embeddings: inout [Float], epsilon: Float) {
        for i in 0..<2 {
            var square_sum: Float = 0
            for j in 0..<embeddingsSize {
                square_sum += pow(embeddings[i * embeddingsSize + j], 2)
            }
            let x_inv_norm = sqrt(max(square_sum, epsilon))
            for j in 0..<embeddingsSize {
                embeddings[i * embeddingsSize + j] = embeddings[i * embeddingsSize + j] / x_inv_norm
            }
        }
    }
    
    private func evaluate(_ embeddings: inout [Float]) -> Float {
        var dist: Float = 0
        for i in 0..<embeddingsSize {
            dist += pow(embeddings[i] - embeddings[i + embeddingsSize], 2)
        }
        var same: Float = 0
        for i in 0..<400 {
            let threshold: Float = 0.01 * Float(i + 1)
            if dist < threshold {
                same += 1.0 / 400
            }
        }
        return same
    }
    
    private func getFace(in image: UIImage, completion: @escaping (Result<UIImage?, Error>) -> ()) {
        guard let ciImage = CIImage(image: image) else {
            let error = NSError(domain: domain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert UIImage to CIImage."])
            
            completion(.failure(error))
            
            return
        }
        
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest { request, error in
            guard error == nil else {
                let error = NSError(domain: domain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Face landmarks detection error: \(error!.localizedDescription)"])
                completion(.failure(error))
                
                return
            }
            
            guard let results = request.results as? [VNFaceObservation],
                    let result = results.first else {
                let error = NSError(domain: domain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get face landmarks detection results."])
                completion(.failure(error))
                
                return
            }
            
            let imageSize = image.size
            
            let faceRect = self.utility.convertUnitToPoint(originalImageRect: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height), targetRect: result.boundingBox)
            
            if let landmarks = result.landmarks,
               let leftEye = landmarks.leftEye,
               let rightEye = landmarks.rightEye,
               let leftEyebrow = landmarks.leftEyebrow,
               let rightEyebrow = landmarks.rightEyebrow,
               let outerLips = landmarks.outerLips {
                
                let minX = min(leftEye.normalizedPoints.min { $0.x < $1.x }?.x ?? 0,
                               leftEyebrow.normalizedPoints.min { $0.x < $1.x }?.x ?? 0) * faceRect.width + faceRect.origin.x
                let maxX = max(rightEye.normalizedPoints.max { $0.x < $1.x }?.x ?? 0,
                               rightEyebrow.normalizedPoints.max { $0.x < $1.x }?.x ?? 0) * faceRect.width + faceRect.origin.x
                let minY = (1 - max(leftEye.normalizedPoints.max { $0.y < $1.y }?.y ?? 0,
                                    leftEyebrow.normalizedPoints.max { $0.y < $1.y }?.y ?? 0,
                                    rightEye.normalizedPoints.max { $0.y < $1.y }?.y ?? 0,
                                    rightEyebrow.normalizedPoints.max { $0.y < $1.y }?.y ?? 0)) * faceRect.height + faceRect.origin.y
                let maxY = (1 - (outerLips.normalizedPoints.min { $0.y < $1.y }?.y ?? 0)) * faceRect.height + faceRect.origin.y
                
                let boundaryRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                
                let path = UIBezierPath(roundedRect: boundaryRect, cornerRadius: boundaryRect.width / 2)
                
                let faceImage = image.imageByApplyingClippingBezierPath(path)
                
                completion(.success(faceImage))
            } else {
                let error = NSError(domain: domain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get face image."])
                
                completion(.failure(error))
            }
        }
        
        let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try requestHandler.perform([faceLandmarksRequest])
        } catch {
            print(error.localizedDescription)
        }
    }
}

