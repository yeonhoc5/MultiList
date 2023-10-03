//
//  MaskAndOrderdListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/21.
//

import SwiftUI

struct MaskAndOrderdListView<Element, RowContent: View>: View where Element: Identifiable {
    let items: [Element]
    private let rowContent: (Element) -> RowContent
    
    private let onTapAction: (Element) -> Void
    private let onMoveAction: (_: IndexSet, _: Int) -> Void
    private let onDeleteAction: (_: IndexSet) -> Void
    
    var isPresentBlurView: Bool
    let blurViewTapAction: () -> Void
    
    @Binding var isPresentAddBttn: Bool
    let addBttnPlaceHolder: String
    @Binding var bindingString: String
    @FocusState var isFocused
    let addBttnAction: () -> Void
    
    @Binding var editMode: EditMode
    
    @State var notHere: Bool = false
    public init(items: [Element],
                editMode: Binding<EditMode>,
                rowContent: @escaping (Element) -> RowContent,
                onTapAction: @escaping (Element) -> Void,
                onMoveAction: @escaping (_ from: IndexSet, _ to: Int) -> Void,
                onDeleteAction: @escaping (_ on: IndexSet) -> Void,
                isPresentBlurView: Bool,
                blurViewTapAction: @escaping () -> Void,
                isPresentAddBttn: Binding<Bool>,
                addBttnPlaceHolder: String,
                bindingStirng: Binding<String>,
                addBttnAction: @escaping () -> Void) {
        self.items = items
        _editMode = editMode
        self.rowContent = rowContent
        self.onTapAction = onTapAction
        self.onMoveAction = onMoveAction
        self.onDeleteAction = onDeleteAction
        self.isPresentBlurView = isPresentBlurView
        self.blurViewTapAction = blurViewTapAction
        _isPresentAddBttn = isPresentAddBttn
        self.addBttnPlaceHolder = addBttnPlaceHolder
        _bindingString = bindingStirng
        self.addBttnAction = addBttnAction
    }
    
    var body: some View {
        Group {
            if items.count > 0 {
                ZStack {
                    listMaskView(color: .white, radius: 10)
                    List {
                        ForEach(items) { item in
                            eachRowView(item: item)
                                .offset(x: editMode == .active ? -38 : 0)
                                .overlay(alignment: .trailing, content: {
                                    if editMode == .active {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.teal)
                                            .imageScale(.large)
                                            .opacity(editMode == .active ? 1 : 0)
                                    }
                                })
                                .onTapGesture(perform: {
                                    onTapAction(item)
                                })
                                .foregroundColor(.black)
                                .listRowBackground(Color.white)
                            }
                            .onMove { indexSet, int in
                                onMoveAction(indexSet, int)
                            }
                            .onDelete { indexSet in
                                onDeleteAction(indexSet)
                            }
                    }
                    .listStyle(.plain)
                    .environment(\.editMode, $editMode)
                }
                .padding(20)
                .mask {
                    listMaskView(color: .white, radius: 10)
                        .padding(20)
                }
                .shadow(color: .black, radius: 1, x: 0, y: 0)
            } else {
                ListEmptyView(title: "버튼을 눌러 리스트를 추가해주세요.",
                              image: "plus.circle.fill",
                              checkBool: $notHere)
            }
        }
        .overlay(alignment: .center) {
            if isPresentBlurView {
                blurViewWithTapAction {
                    blurViewTapAction()
                    isFocused = false
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay(alignment: .bottomLeading) {
            AddButton(width: screenSize.width,
                      placeHolder: addBttnPlaceHolder,
                      isPresented: $isPresentAddBttn,
                      string: $bindingString,
                      isFocused: $isFocused) {
                addBttnAction()
            }
                      .padding(.horizontal, 10)
        }
    }
    
    func eachRowView(item: Element) -> some View {
        rowContent(item)
            .padding(.leading, 35)
            .background(alignment: .leading) {
                if let index = items.firstIndex(where: {$0.id == item.id}) {
                    Text(index < 9 ? "0\(index + 1)" : "\(index + 1)")
                        .foregroundStyle(Color.numberingGray)
                        .font(Font.system(size: 50, weight: .black, design: .monospaced))
                        .italic()
                        .kerning(-5)
                        .offset(x: -28)
                }
            }
    }
    
}

struct MaskAndOrderedListView_Previews: PreviewProvider {
    static var previews: some View {
        MaskAndOrderdListView(items: sampleShareMulti, editMode: .constant(.inactive), rowContent: { item in
            Text(item.title)
        }, onTapAction: { item in
            print("tapped", item.title)
        }, onMoveAction: { from, to in
            print(from, to)
        }, onDeleteAction: { indexSet in
            print("deleted", indexSet)
        }, isPresentBlurView: false, blurViewTapAction: {
            
        }, isPresentAddBttn: .constant(true), addBttnPlaceHolder: "추가할 리스트", bindingStirng: .constant("")) {
                
        }
    }
}
