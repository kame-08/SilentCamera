//
//  ContentView.swift
//  SilentCamera
//
//  Created by Ryo on 2022/06/14.
//

import SwiftUI

struct ContentView: View {
    
    var viewModel = ViewModel()
    
    var body: some View {
        CameraViewRepresent(viewModel: viewModel)
            .gesture(
                TapGesture()
                    .onEnded {
                        viewModel.takePhoto()
                    }
            )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
