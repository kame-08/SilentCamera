//
//  ContentView.swift
//  SilentCamera
//
//  Created by Ryo on 2022/06/14.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraViewRepresent()
            .gesture(
                TapGesture()
                    .onEnded {
                        takePhoto()
                    }
            )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
