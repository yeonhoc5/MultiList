//
//  OrientationView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/15.
//

import SwiftUI

struct OrientationView: View {
    @State var orientation = UIDeviceOrientation.portrait
    
    var body: some View {
        Group {
            if orientation.isPortrait {
                Text("is Portrait")
            } else {
                Text("is Landscape")
            }
        }
        .onRotate { newValue in
            orientation = newValue
        }
    }
}

struct OrientationView_Previews: PreviewProvider {
    static var previews: some View {
        OrientationView()
    }
}
