//
//  Data.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 16.08.2021.
//

import UIKit

extension Data {    
    var uint8: UInt8 {
        var number: UInt8 = 0
        self.copyBytes(to:&number, count: MemoryLayout<UInt8>.size)
        return number
    }
    
    func createChunks(chunkSize: Int) -> [Data] {
      var chunks : [Data] = []
      let length = count
        var offset = 0
        repeat {
          // get the length of the chunk
          let thisChunkSize = ((length - offset) > chunkSize) ? chunkSize : (length - offset);
          // get the chunk
          let chunk = subdata(in: offset..<offset + thisChunkSize )
          chunks.append(chunk)
          // update the offset
          offset += thisChunkSize;
        } while (offset < length);
        return chunks
    }
}
