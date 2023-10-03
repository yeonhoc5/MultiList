//
//  PhotosPickerView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/25.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseStorage

struct PhotosPickerView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: PhotosPickerViewModel
    @State var myItem: MyItemModel!
    
    @Binding var isEditMode: Bool
    
    @FocusState var isFocused
    @State var isShowingProgressView: Bool = false
    
    @Namespace var animationID
    
    // myItem 공통
    @Binding var itemNumber: Int
    @State var itemTitle: String = ""
    
    // type 1. 사진
    @Binding var isShowingItemView: Bool
    @Binding var selectedPhoto: [PhotosPickerItem]
    @Binding var itemPhoto: UIImage! {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isShowingProgressView = false
            }
        }
    }
    
    init(userData: UserData, isShowingItemView: Binding<Bool>, itemNumber: Binding<Int>, itemPhoto: Binding<UIImage?>, selectedPhoto: Binding<[PhotosPickerItem]>, isEditMode: Binding<Bool>, myItem: MyItemModel?) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: PhotosPickerViewModel(userData: userData))
        _itemNumber = itemNumber
        _isShowingItemView = isShowingItemView
        _itemPhoto = itemPhoto
        _isEditMode = isEditMode
        _selectedPhoto = selectedPhoto
        self.myItem = myItem
    }
    
    
    var body: some View {
        PhotosPicker(selection: $selectedPhoto, maxSelectionCount: 1, matching: .images) {
            Group {
                if self.isEditMode {
                    VStack {
                        Group {
                            if itemPhoto == nil {
                                if #available(iOS 17, *) {
                                    pickerTapImageVer17
                                } else {
                                    pickerTapImageVer16
                                }
                            } else {
                                if #available(iOS 17, *) {
                                    selectedPhotoView17
                                } else {
                                    selectedPhotoView16
                                }
                            }
                        }
                        .frame(width: 200, height:  200)
                        Group {
                            if itemPhoto == nil {
                                Text("사진을 선택하면 서버 및 앱에 저장합니다.")
                            } else {
                                Text("사진을 교체하려면 사진을 클릭해주세요.")
                            }
                        }
                        .font(.callout)
                    }
                } else {
                    if itemPhoto == nil {
                        if #available(iOS 17, *) {
                            ProgressView()
                                .frame(width: screenSize.width)
                                .onChange(of: userData.myItems[itemNumber]?.itemPhoto, {
                                    if let photo = userData.myItems[itemNumber]?.itemPhoto {
                                        self.itemPhoto = photo
                                    }
                                })
                        } else {
                            ProgressView()
                                .frame(width: screenSize.width)
                                .onChange(of: userData.myItems[itemNumber]?.itemPhoto) { photo in
                                    if let photo = photo {
                                        self.itemPhoto = photo
                                    }
                                }
                        }
                    } else {
                        if #available(iOS 17, *) {
                            selectedPhotoView17
                        } else {
                            selectedPhotoView16
                        }
                    }   
                }
            }
            .overlay {
                if isShowingProgressView {
                    CustomProgressView()
                }
            }
        }
        .disabled(!isEditMode)
    }
}


extension PhotosPickerView {
    @available(iOS 17.0, *)
    var pickerTapImageVer17: some View {
        Image(systemName: "hand.tap.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 70, height:  70)
            .overlay(alignment: .topTrailing) {
                Text("Tap Here")
                    .font(.callout)
                    .offset(x: 50)
            }
            .onChange(of: selectedPhoto) { oldValue, newValue in
                print(oldValue, newValue)
                if oldValue != newValue {
                    if !newValue.isEmpty {
                        self.isShowingProgressView = true
                    }
                    viewModel.loadPhoto(item: self.selectedPhoto, result: { image in
                        self.itemPhoto = image
                        self.isFocused = true
                    })
                }
            }
    }
    
    var pickerTapImageVer16: some View {
        Image(systemName: "hand.tap.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height:  100)
            .overlay(alignment: .topTrailing) {
                Text("Touch Here")
                    .offset(x: 50)
            }
            .buttonStyle(ScaleEffect())
            .onChange(of: selectedPhoto, perform: { value in
                if value.count != 0 {
                    self.isShowingProgressView = true
                }
                Task {
                    if let photo = value.first, let data = try? await photo.loadTransferable(type: Data.self) {
                        self.itemPhoto = UIImage(data: data)
                    }
                }
                self.isFocused = true
            })
    }
    @available(iOS 17.0, *)
    var selectedPhotoView17: some View {
        Image(uiImage: itemPhoto)
            .resizable()
            .scaledToFit()
            .matchedGeometryEffect(id: "photoView", in: animationID)
            .onChange(of: selectedPhoto) { oldValue, newValue in
                print(oldValue, newValue)
                if oldValue != newValue {
                    if !newValue.isEmpty {
                        self.isShowingProgressView = true
                    }
                    viewModel.loadPhoto(item: self.selectedPhoto, result: { image in
                        self.itemPhoto = image
                        self.isFocused = true
                    })
                }
            }
    }
    
    var selectedPhotoView16: some View {
        Image(uiImage: itemPhoto)
            .resizable()
            .scaledToFit()
            .matchedGeometryEffect(id: "photoView", in: animationID)
            .onChange(of: selectedPhoto, perform: { value in
                if value.count != 0 {
                    self.isShowingProgressView = true
                }
                Task {
                    if let photo = value.first, let data = try? await photo.loadTransferable(type: Data.self) {
                        self.itemPhoto = UIImage(data: data)
                    }
                }
                self.isFocused = true
            })
    }
    
    func fetchingImage(asset: PHAsset) -> UIImage {
        var returnImage: UIImage!
        let imageManager = PHImageManager()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        let width = 200
        let size = CGSize(width: width, height: 200)
        
        imageManager.requestImage(for: asset,
                                  targetSize: size,
                                  contentMode: .aspectFit,
                                  options: options) { assetImage, _ in
            if let image = assetImage {
                returnImage = image
            }
        }
        return returnImage
    }
}
                
                
//#Preview {
//    PhotosPickerView(userData: UserData(), isShowingPhotosPicekr: .constant(true))
//}
