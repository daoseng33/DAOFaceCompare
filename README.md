# DAOFaceCompare

A simple tool to compare faces.

[![CI Status](https://img.shields.io/travis/DAO/DAOFaceCompare.svg?style=flat)](https://travis-ci.org/DAO/DAOFaceCompare)
[![Version](https://img.shields.io/cocoapods/v/DAOFaceCompare.svg?style=flat)](https://cocoapods.org/pods/DAOFaceCompare)
[![License](https://img.shields.io/cocoapods/l/DAOFaceCompare.svg?style=flat)](https://cocoapods.org/pods/DAOFaceCompare)
[![Platform](https://img.shields.io/cocoapods/p/DAOFaceCompare.svg?style=flat)](https://cocoapods.org/pods/DAOFaceCompare)

![IMG_3276](https://github.com/daoseng33/DAOFaceCompare/assets/6115078/ae2bf0ca-65de-42d3-a7c5-ceef1276aa79)

## Example
```swift
do {
    // Compare faces
    let faceCompare = try DAOFaceCompare()
    faceCompare.compare(image1, with: image2, completion: { [weak self] result in
    guard let self = self else { return }
    switch result {
      case .success(let score):
      print(score)
      case .failure(let error):
      print(error.localizedDescription)
    }
    })
} catch {
    print(error.localizedDescription)
}
```
To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
- iOS 13
- Swift 5

## Installation

DAOFaceCompare is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'DAOFaceCompare'
```

## Author

DAO, daoseng33@gmail.com

## License

DAOFaceCompare is available under the MIT license. See the LICENSE file for more info.
