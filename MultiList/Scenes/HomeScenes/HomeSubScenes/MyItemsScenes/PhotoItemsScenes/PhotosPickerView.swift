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
    @Binding var photoSize: Double
    
    
    init(userData: UserData, isShowingItemView: Binding<Bool>, itemNumber: Binding<Int>, itemPhoto: Binding<UIImage?>, selectedPhoto: Binding<[PhotosPickerItem]>, isEditMode: Binding<Bool>, myItem: MyItemModel?, photoSize: Binding<Double>) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: PhotosPickerViewModel(userData: userData))
        _itemNumber = itemNumber
        _isShowingItemView = isShowingItemView
        _itemPhoto = itemPhoto
        _isEditMode = isEditMode
        _selectedPhoto = selectedPhoto
        _photoSize = photoSize
        self.myItem = myItem
    }
    
    
    var body: some View {
        VStack {
//            if itemPhoto != nil && isEditMode {
//                Text("\(photoSize, specifier: "%.2f") MB")
//            }
//            if photoSize > 30 {
//                Text("이미지 업로드는 30MB 이하로 제한합니다")
//                    .foregroundStyle(Color.red)
//            }
            PhotosPicker(selection: $selectedPhoto, maxSelectionCount: 1, matching: .images) {
                Group {
                    if self.isEditMode {
                        Group {
                            if itemPhoto == nil {
                                if #available(iOS 17, *) {
                                    pickerTapImageVer17
                                } else {
                                    pickerTapImageVer16
                                }
                            } else {
                                Group {
                                    if #available(iOS 17, *) {
                                        selectedPhotoView17
                                    } else {
                                        selectedPhotoView16
                                    }
                                }
                                .onAppear {
                                    self.photoSize = viewModel.returnPhotoSize(photo: itemPhoto)
                                }
                            }
                        }
                        .frame(width: 200, height:  200)
                        .padding(10)
                    } else {
                        if itemPhoto == nil {
                            if #available(iOS 17, *) {
                                ProgressView()
                                    .frame(width: screenSize.width)
                                    .onChange(of: userData.myItems[itemNumber]?.itemPhoto, {
                                        if let photo = userData.myItems[itemNumber]?.itemPhoto {
                                            withAnimation {
                                                self.itemPhoto = photo
                                            }
                                        }
                                    })
                            } else {
                                ProgressView()
                                    .frame(width: screenSize.width)
                                    .onChange(of: userData.myItems[itemNumber]?.itemPhoto) { photo in
                                        if let photo = photo {
                                            withAnimation {
                                                self.itemPhoto = photo
                                            }
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
            .foregroundStyle(Color.orange)
            .buttonStyle(ScaleEffect(scale: 0.9))
            .disabled(!isEditMode)
            .onAppear(perform: {
                if let itemPhoto = self.itemPhoto {
                   self.photoSize = viewModel.returnPhotoSize(photo: itemPhoto)
                }
            })
            Group {
                if isEditMode && itemPhoto != nil {
                    Text("사진을 교체하려면 사진을 클릭해주세요.")
                } else if myItem == nil && itemPhoto == nil {
                    Text("파일 사이즈를 축소하여 업로드하므로\n사진 품질이 다소 저하될 수 있습니다.")
                }
            }
            .font(.callout)

        }
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
                    self.isShowingProgressView = !newValue.isEmpty
                    viewModel.loadPhoto(item: self.selectedPhoto, result: { image, volume in
                        withAnimation {
                            self.itemPhoto = image
                        }
                        self.photoSize = volume
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
                self.isShowingProgressView = value.count != 0
                viewModel.loadPhoto(item: self.selectedPhoto, result: { image, volume in
                    withAnimation {
                        self.itemPhoto = image
                    }
                    self.photoSize = volume
                })
            })
    }
    @available(iOS 17.0, *)
    var selectedPhotoView17: some View {
        Image(uiImage: itemPhoto)
            .resizable()
            .scaledToFit()
            .matchedGeometryEffect(id: "photoView", in: animationID)
            .onChange(of: selectedPhoto) { oldValue, newValue in
                if oldValue != newValue {
                    self.isShowingProgressView = !newValue.isEmpty
                    viewModel.loadPhoto(item: selectedPhoto) { image, volume in
                        withAnimation {
                            self.itemPhoto = image
                        }
                        self.photoSize = volume
                        
                    }
                }
            }
    }
    
    var selectedPhotoView16: some View {
        Image(uiImage: itemPhoto)
            .resizable()
            .scaledToFit()
            .matchedGeometryEffect(id: "photoView", in: animationID)
            .onChange(of: selectedPhoto, perform: { value in
                self.isShowingProgressView = value.count != 0
                viewModel.loadPhoto(item: selectedPhoto) { image, volume in
                    withAnimation {
                        self.itemPhoto = image
                    }
                    self.photoSize = volume
                }
            })
    }
    
}
                
                
//#Preview {
//    PhotosPickerView(userData: UserData(), isShowingPhotosPicekr: .constant(true))
//}
